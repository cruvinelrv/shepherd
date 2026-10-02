import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../entities/ai_file_action_entity.dart';
import '../entities/ai_token_usage_entity.dart';
import 'ai_direct_inference_service.dart';
import 'ai_file_patch_service.dart';
import '../../data/models/ai_file_action_model.dart';
import 'ai_jsonl_protocol.dart';
import 'ai_keep_alive.dart';
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

  /// How often a `status` event is sent while a step is silent.
  final Duration heartbeat;
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
    this.heartbeat = const Duration(seconds: 5),
  })  : _generate = generate ?? AiDirectInferenceService().generateStream,
        _rag = rag;

  /// Completed by [cancel] so a turn stuck waiting for a silent provider stops
  /// at once instead of at the next chunk, which may never come.
  Completer<void> _cancelSignal = Completer<void>();
  String _phase = 'indexing';

  void cancel() {
    _cancelled = true;
    if (!_cancelSignal.isCompleted) _cancelSignal.complete();
  }

  /// Changes the selected projects mid-conversation (history is kept). The
  /// newly in-scope projects are indexed before the next question.
  void setProjects(List<String> selected) {
    projects = List.unmodifiable(selected);
    final rag = _rag;
    if (rag == null) return;
    rag.projects = projects;
    _indexChain = _indexChain.then((_) => rag.indexScope()).catchError((_) {});
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
      _phase = 'indexing';
      await for (final event in keepAlive(
        rag.prepare(),
        every: heartbeat,
        beat: (q) =>
            AiEvent.status(phase: 'indexing', idleSeconds: q.inSeconds),
      )) {
        yield event;
      }
    } catch (e) {
      _rag = null;
      yield AiEvent.ragUnavailable(e.toString());
    } finally {
      prepared.complete();
    }
  }

  /// One conversation turn as events, with a `status` sign of life whenever it
  /// goes quiet (a model still loading, a long search).
  Stream<AiEvent> ask(String question) => keepAlive(
        _ask(question),
        every: heartbeat,
        beat: (q) => AiEvent.status(phase: _phase, idleSeconds: q.inSeconds),
      );

  Stream<AiEvent> _ask(String question) async* {
    _cancelled = false;
    _cancelSignal = Completer<void>();
    _phase =
        _prepared != null && !_prepared!.isCompleted ? 'indexing' : 'searching';
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

      _phase = 'waiting_model';
      final prose = StringBuffer();
      final chunks = StreamIterator(stream);
      try {
        while (!_cancelled) {
          // Race the next chunk against cancel(): a provider that says nothing
          // must not make Stop wait for it.
          final more = await Future.any([
            chunks.moveNext(),
            _cancelSignal.future.then((_) => false),
          ]);
          if (!more || _cancelled) break;
          final item = chunks.current;
          if (item.isReasoning) {
            _phase = 'thinking';
            yield AiEvent.reasoningDelta(item.text);
            continue;
          }
          _phase = 'writing';
          raw.write(item.text);
          for (final part in splitter.feed(item.text)) {
            yield* _emitSplit(part, prose);
          }
        }
      } finally {
        // Closing the stream aborts a request still in flight. Not awaited: if
        // the provider is unresponsive this must not hold the turn up.
        unawaited(chunks.cancel());
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
        final resolved = _resolve(path);
        if (resolved.path != null) yield AiEvent.fileStarted(resolved.path!);
    }
  }

  Stream<AiEvent> _proposals(String rawAnswer) async* {
    if (mode == 'plan') return;
    for (final action in AiFilePatchService.extractActions(rawAnswer)) {
      final resolved = _resolve(action.path);
      if (resolved.path == null) {
        yield AiEvent.fileBlocked(action.path, resolved.reason!);
        continue;
      }
      // extractActions looked the file up by the path as written; look it up
      // again at the resolved location so create/modify and the diff are right.
      final file = File(p.join(workspaceRoot, resolved.path!));
      final exists = file.existsSync();
      final fixed = AiFileActionModel(
        path: resolved.path!,
        actionType: exists ? AiFileActionType.modify : AiFileActionType.create,
        newContent: action.newContent,
        originalContent: exists ? file.readAsStringSync() : null,
      );
      final id = 'p${_counter++}';
      _pending[id] = fixed;
      yield AiEvent.fileProposal(
        id: id,
        path: fixed.path,
        content: fixed.newContent ?? '',
        isNew: fixed.actionType == AiFileActionType.create,
      );
      // Auto mode: no approval step; the file is written right away.
      if (mode == 'auto') yield confirm(id, approved: true);
    }
  }

  /// Applies or discards a proposal. Returns the event to report.
  AiEvent confirm(String id, {required bool approved}) {
    final action = _pending.remove(id);
    if (action == null) {
      return AiEvent.error('bad_request', 'Proposta desconhecida: $id');
    }
    final applied = approved &&
        AiFilePatchService.applyAction(action, basePath: workspaceRoot);
    final rag = _rag;
    if (applied && rag != null) {
      // Keep the index in step with what the AI just wrote; the next
      // question waits for this to finish.
      final project = p.posix
          .split(p.posix.normalize(action.path.replaceAll('\\', '/')))
          .first;
      _indexChain = _indexChain
          .then((_) => rag.reindexProject(project))
          .catchError((_) {});
    }
    return AiEvent.fileResult(id: id, path: action.path, applied: applied);
  }

  /// Maps the path the model wrote to one relative to the workspace root, or
  /// says why it may not be touched.
  ///
  /// It must stay inside the workspace and, when projects are selected, inside
  /// one of them. With exactly one project selected, models naturally write
  /// paths relative to that project (`lib/main.dart`), so those are placed
  /// inside it, unless the first segment is another existing folder of the
  /// workspace (an explicit path into a project that is not selected).
  ({String? path, String? reason}) _resolve(String raw) {
    var n = p.posix.normalize(raw.replaceAll('\\', '/'));
    if (n.startsWith('./')) {
      n = n.substring(2);
    }
    if (p.posix.isAbsolute(n) || n == '..' || n.startsWith('../')) {
      return (path: null, reason: 'fora do workspace');
    }
    if (projects.isEmpty) return (path: n, reason: null);

    final selected = projects
        .map((e) => p.posix.normalize(e.replaceAll('\\', '/')))
        .toList();
    if (selected.any((proj) => n == proj || n.startsWith('$proj/'))) {
      return (path: n, reason: null);
    }
    if (selected.length == 1) {
      final first = n.split('/').first;
      if (Directory(p.join(workspaceRoot, first)).existsSync()) {
        return (path: null, reason: 'fora dos projetos selecionados');
      }
      return (path: '${selected.single}/$n', reason: null);
    }
    return (
      path: null,
      reason:
          'comece o caminho pela pasta de um projeto selecionado (${selected.join(', ')})',
    );
  }

  String _buildPrompt(String question, String ragContext) {
    final b = StringBuffer()
      ..writeln(formatAiSystemPreamble(
          workingDir: workspaceRoot, isLocal: settings.isLocal))
      ..writeln(projects.isEmpty
          ? 'Escopo: todos os projetos (pastas) deste workspace.'
          : projects.length == 1
              ? 'Escopo: você está trabalhando no projeto ${projects.single} '
                  '(a pasta ${projects.single} dentro do workspace). Tudo o que criar ou '
                  'alterar fica dentro dela.'
              : 'Escopo: apenas os projetos ${projects.join(', ')} (pastas na raiz do workspace). '
                  'Não proponha arquivos fora delas.')
      ..writeln();
    final context =
        readAiWorkspaceContext(includeWorkspace: true, projects: projects);
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
      b.writeln(
          'Modo PLANO: descreva o plano passo a passo, sem gerar arquivos.\n');
    } else {
      b.write(_fileFormatPrompt(projects));
    }
    b.write(formatAiTierPrompt(tier));
    if (_history.isNotEmpty) {
      b.writeln('--- Histórico Recente da Conversa ---');
      for (final h
          in _history.skip(_history.length > 12 ? _history.length - 12 : 0)) {
        b.writeln(
            '${h.role == 'user' ? 'Usuário' : 'Assistente'}: ${h.content}');
      }
      b.writeln();
    }
    b.writeln(question);
    return b.toString().trim();
  }

  static String _fileFormatPrompt(List<String> projects) {
    final where = projects.length == 1
        ? 'o caminho relativo à pasta do projeto ${projects.single} (por exemplo `lib/main.dart`)'
        : 'o caminho relativo à raiz do workspace, começando pela pasta do projeto '
            '(por exemplo `meu-site/index.html`)';
    return '--- Como entregar arquivos ---\n'
        'Para criar ou alterar arquivos, use blocos assim, com $where e o conteúdo '
        'COMPLETO do arquivo:\n'
        '```linguagem\n'
        '// FILE: caminho/do/arquivo.ext\n'
        'conteúdo completo\n'
        '```\n'
        'O aplicativo mostra ao usuário um cartão com os botões Aplicar e Descartar para '
        'cada arquivo. NÃO peça aprovação por texto (não escreva "responda Aprovado" nem '
        '"vou esperar sua aprovação"): basta entregar os blocos. Se não houver arquivo a '
        'gravar, apenas responda. Explique em linguagem simples o que está fazendo, sem '
        'repetir o código fora dos blocos.\n\n';
  }

  static String _errorCode(Object e) {
    final m = e.toString();
    if (m.contains('11434') || m.contains('Connection refused')) {
      return 'ollama_offline';
    }
    if (m.contains('Chave de API') ||
        m.contains('401') ||
        m.contains('API key')) {
      return 'invalid_key';
    }
    return 'unknown';
  }
}
