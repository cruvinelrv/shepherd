import 'dart:async';

import 'package:path/path.dart' as p;

import '../entities/ai_file_action_entity.dart';
import '../entities/ai_token_usage_entity.dart';
import 'ai_direct_inference_service.dart';
import 'ai_file_patch_service.dart';
import 'ai_jsonl_protocol.dart';
import 'ai_prompt_builder.dart';
import 'ai_reasoning_stream_transformer.dart';
import 'ai_session_rag.dart';
import 'ai_settings_resolver.dart';
import 'ai_stream_splitter.dart';

typedef AiGenerate = Stream<String> Function({
  required String prompt,
  required String provider,
  required String model,
  String? apiKey,
  String? baseUrl,
  void Function(AiTokenUsageEntity usage)? onUsage,
});

/// Runs conversation turns against the configured provider and reports them
/// as [AiEvent]s, with no terminal I/O. File changes are proposed, never
/// written, until [confirm] is called.
///
/// The process working directory must be the workspace root: workspace files
/// (`.shepherd/*.yaml`) and existing-file checks resolve against it.
class AiSessionRunner {
  AiResolvedSettings settings;
  String mode;
  String tier;

  /// Project folders (relative to the workspace root) the model may see and
  /// change; empty means the whole workspace. Change it with [setProjects].
  List<String> projects;
  final String workspaceRoot;
  final AiGenerate _generate;
  AiSessionRag? _rag;

  final List<({String role, String content})> _history = [];
  final Map<String, AiFileActionEntity> _pending = {};
  int _counter = 0;
  bool _cancelled = false;

  AiSessionRunner({
    required this.settings,
    required this.workspaceRoot,
    this.projects = const [],
    this.mode = 'fast',
    this.tier = 'fast',
    AiGenerate? generate,
    AiSessionRag? rag,
  })  : _generate = generate ?? AiDirectInferenceService().generateStream,
        _rag = rag;

  void cancel() => _cancelled = true;

  /// Changes the selected projects mid-conversation (history is kept). The
  /// newly in-scope projects are indexed before the next question.
  void setProjects(List<String> selected) {
    projects = List.unmodifiable(selected);
    final rag = _rag;
    if (rag == null) return;
    rag.projects = projects;
    _indexChain = _indexChain
        .then((_) => rag.indexScope())
        .catchError((_) {});
  }

  Completer<void>? _prepared;
  Future<void> _indexChain = Future.value();

  /// Starts RAG indexing; the first question waits for it. Failures turn RAG
  /// off (reported as `rag_unavailable`) without ending the conversation.
  Stream<AiEvent> prepare() async* {
    final rag = _rag;
    if (rag == null) return;
    final prepared = _prepared = Completer<void>();
    try {
      // `await for`, not `yield*`: yield* forwards errors instead of throwing,
      // which would bypass this catch.
      await for (final event in rag.prepare()) {
        yield event;
      }
    } catch (e) {
      _rag = null;
      yield AiEvent.ragUnavailable(e.toString());
    } finally {
      prepared.complete();
    }
  }

  Stream<AiEvent> ask(String question) async* {
    _cancelled = false;
    final splitter = AiStreamSplitter();
    final raw = StringBuffer();
    AiTokenUsageEntity? usage;

    try {
      await _prepared?.future;
      await _indexChain;
      var ragContext = '';
      final rag = _rag;
      if (rag != null) {
        try {
          final r = await rag.contextFor(question, isLocal: settings.isLocal);
          if (r.chunks > 0) {
            ragContext = r.context;
            yield AiEvent.ragContext(chunks: r.chunks, files: r.files);
          }
        } catch (e) {
          yield AiEvent.ragUnavailable(e.toString());
        }
      }

      final stream = _generate(
        prompt: _buildPrompt(question, ragContext),
        provider: settings.provider,
        model: settings.model,
        apiKey: settings.apiKey,
        baseUrl: settings.baseUrl,
        onUsage: (u) => usage = u,
      ).transform(const AiReasoningStreamTransformer());

      final prose = StringBuffer();
      await for (final item in stream) {
        if (_cancelled) break;
        if (item.isReasoning) {
          yield AiEvent.reasoningDelta(item.text);
          continue;
        }
        raw.write(item.text);
        for (final part in splitter.feed(item.text)) {
          yield* _emitSplit(part, prose);
        }
      }
      for (final part in splitter.flush()) {
        yield* _emitSplit(part, prose);
      }

      if (!_cancelled) {
        yield* _proposals(raw.toString());
        _history
          ..add((role: 'user', content: question))
          ..add((role: 'assistant', content: prose.toString().trim()));
        final u = usage;
        if (u != null) {
          yield AiEvent.usage(
            promptTokens: u.promptTokens,
            completionTokens: u.completionTokens,
            isLocal: u.isLocal,
          );
        }
      }
      yield AiEvent.done();
    } catch (e) {
      yield AiEvent.error(_errorCode(e), e.toString());
    }
  }

  Stream<AiEvent> _emitSplit(AiSplit part, StringBuffer prose) async* {
    switch (part) {
      case AiSplitText(:final text):
        prose.write(text);
        yield AiEvent.textDelta(text);
      case AiSplitFileStarted(:final path):
        if (_blockReason(path) == null) yield AiEvent.fileStarted(path);
    }
  }

  Stream<AiEvent> _proposals(String rawAnswer) async* {
    if (mode == 'plan') return;
    for (final action in AiFilePatchService.extractActions(rawAnswer)) {
      final reason = _blockReason(action.path);
      if (reason != null) {
        yield AiEvent.fileBlocked(action.path, reason);
        continue;
      }
      final id = 'p${_counter++}';
      _pending[id] = action;
      yield AiEvent.fileProposal(
        id: id,
        path: action.path,
        content: action.newContent ?? '',
        isNew: action.actionType == AiFileActionType.create,
      );
    }
  }

  /// Applies or discards a proposal. Returns the event to report.
  AiEvent confirm(String id, {required bool approved}) {
    final action = _pending.remove(id);
    if (action == null) return AiEvent.error('bad_request', 'Proposta desconhecida: $id');
    final applied = approved &&
        AiFilePatchService.applyAction(action, basePath: workspaceRoot);
    final rag = _rag;
    if (applied && rag != null) {
      // Keep the index in step with what the AI just wrote; the next
      // question waits for this to finish.
      final project = p.posix.split(p.posix.normalize(action.path.replaceAll('\\', '/'))).first;
      _indexChain = _indexChain.then((_) => rag.reindexProject(project)).catchError((_) {});
    }
    return AiEvent.fileResult(id: id, path: action.path, applied: applied);
  }

  /// Why [path] may not be touched, or null if it is allowed: it must stay
  /// inside the workspace and, when projects are selected, inside one of them.
  String? _blockReason(String path) {
    final n = p.posix.normalize(path.replaceAll('\\', '/'));
    if (p.posix.isAbsolute(n) || n == '..' || n.startsWith('../')) {
      return 'fora do workspace';
    }
    if (projects.isEmpty) return null;
    final allowed = projects.map((e) => p.posix.normalize(e.replaceAll('\\', '/')));
    final ok = allowed.any((proj) => n == proj || n.startsWith('$proj/'));
    return ok ? null : 'fora dos projetos selecionados';
  }

  String _buildPrompt(String question, String ragContext) {
    final b = StringBuffer()
      ..writeln(formatAiSystemPreamble(workingDir: workspaceRoot, isLocal: settings.isLocal))
      ..writeln(projects.isEmpty
          ? 'Escopo: todos os projetos (pastas) deste workspace.'
          : 'Escopo: apenas os projetos ${projects.join(', ')} (pastas na raiz do workspace). '
              'Não proponha arquivos fora delas.')
      ..writeln();
    final context = readAiWorkspaceContext(includeWorkspace: true, projects: projects);
    if (context.isNotEmpty) {
      b
        ..writeln('--- Contexto do Workspace Shepherd ---')
        ..writeln(context)
        ..writeln();
    }
    if (ragContext.isNotEmpty) {
      b
        ..writeln(ragContext)
        ..writeln();
    }
    if (mode == 'plan') {
      b.writeln('Modo PLANO: descreva o plano passo a passo, sem gerar arquivos.\n');
    } else {
      b.write(_fileFormatPrompt);
    }
    b.write(formatAiTierPrompt(tier));
    if (_history.isNotEmpty) {
      b.writeln('--- Histórico Recente da Conversa ---');
      for (final h in _history.skip(_history.length > 12 ? _history.length - 12 : 0)) {
        b.writeln('${h.role == 'user' ? 'Usuário' : 'Assistente'}: ${h.content}');
      }
      b.writeln();
    }
    b.writeln(question);
    return b.toString().trim();
  }

  static const _fileFormatPrompt = '--- Como entregar arquivos ---\n'
      'Para criar ou alterar arquivos, use blocos assim, com o caminho relativo à raiz do '
      'workspace e o conteúdo COMPLETO do arquivo:\n'
      '```linguagem\n'
      '// FILE: projeto/caminho/arquivo.ext\n'
      'conteúdo completo\n'
      '```\n'
      'O usuário aprova cada arquivo antes de ele ser gravado. Explique em linguagem simples '
      'o que está fazendo, sem repetir o código fora dos blocos.\n\n';

  static String _errorCode(Object e) {
    final m = e.toString();
    if (m.contains('11434') || m.contains('Connection refused')) return 'ollama_offline';
    if (m.contains('Chave de API') || m.contains('401') || m.contains('API key')) {
      return 'invalid_key';
    }
    return 'unknown';
  }
}
