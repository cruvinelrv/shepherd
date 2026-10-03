import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shepherd/src/tools/domain/services/ai_config_service.dart'
    show AiConfigModel;
import 'package:shepherd/src/tools/domain/services/ai_embedding_service.dart';
import 'package:shepherd/src/tools/domain/services/ai_jsonl_protocol.dart';
import 'package:shepherd/src/tools/domain/services/ai_session_rag.dart';
import 'package:shepherd/src/tools/domain/services/ai_session_runner.dart';
import 'package:shepherd/src/tools/domain/services/ai_settings_resolver.dart';
import 'package:test/test.dart';

/// Deterministic stand-in for a real backend. Any text containing FLIP makes
/// it "fall back" to another source, like Ollama timing out would.
class _FakeEmbedding extends AiEmbeddingService {
  final String source;
  _FakeEmbedding([this.source = 'fake']);

  @override
  Future<List<double>> getEmbedding(String text,
      {AiConfigModel? config}) async {
    lastSource = text.contains('FLIP') ? 'local' : source;
    return AiEmbeddingService.computeLocalDenseVector(text);
  }
}

void main() {
  late Directory tmp;
  late Directory previous;

  void write(String rel, String content) {
    final f = File(p.join(tmp.path, rel))..parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  }

  setUp(() {
    previous = Directory.current;
    tmp = Directory(Directory.systemTemp
        .createTempSync('ai_rag')
        .resolveSymbolicLinksSync());
    Directory.current = tmp;
    // Two registered projects, like Shepherd Studio writes them.
    write('.shepherd/workspace.yaml', '''
workspace:
  name: "ws"
  version: "1.0.0"
  projects:
    apps:
      - id: "frutas"
        name: "frutas"
        path: "frutas"
      - id: "oficina"
        name: "oficina"
        path: "oficina"
''');
    write('frutas/index.html',
        '<h1>receita de bolo de banana com canela e açúcar mascavo</h1>');
    write('oficina/index.html',
        '<h1>manual do motor do trator, troca de óleo e filtro diesel</h1>');
  });
  tearDown(() {
    Directory.current = previous;
    tmp.deleteSync(recursive: true);
  });

  Future<AiSessionRag> prepared(
      {List<String> projects = const [], AiEmbeddingService? emb}) async {
    final rag = AiSessionRag(
        workspaceRoot: tmp.path,
        projects: projects,
        embedding: emb ?? _FakeEmbedding());
    await rag.prepare().toList();
    return rag;
  }

  test('indexes each registered project and retrieves by meaning', () async {
    final rag =
        AiSessionRag(workspaceRoot: tmp.path, embedding: _FakeEmbedding());
    final events = await rag.prepare().toList();
    expect(
        events
            .where(
                (e) => e.type == 'index_progress' && e.data['phase'] == 'done')
            .length,
        2);
    expect(events.last.type, 'index_done');
    expect(events.last.data['source'], 'fake');

    final r = await rag.contextFor('receita de bolo de banana', isLocal: true);
    expect(r.files, contains('frutas/index.html'));
    expect(r.context, contains('banana'));
  });

  test('selected projects limit what can be retrieved', () async {
    final rag = await prepared(projects: ['oficina']);
    final r =
        await rag.contextFor('receita de bolo de banana canela', isLocal: true);
    expect(r.files.where((f) => f.startsWith('frutas/')), isEmpty);
  });

  test('same file name in two projects does not collide', () async {
    final rag = await prepared();
    final a = await rag.contextFor('bolo de banana', isLocal: true);
    final b = await rag.contextFor('trator diesel filtro', isLocal: true);
    expect(a.files, contains('frutas/index.html'));
    expect(b.files, contains('oficina/index.html'));
  });

  test('a different embedding backend rebuilds the index instead of mixing',
      () async {
    await prepared();
    final sig =
        File(p.join(tmp.path, '.shepherd', 'vectors', 'embedding_signature'));
    expect(sig.readAsStringSync(), startsWith('fake:'));

    final rag = await prepared(emb: _FakeEmbedding('other'));
    expect(sig.readAsStringSync(), startsWith('other:'));
    final r = await rag.contextFor('bolo de banana', isLocal: true);
    expect(r.files, contains('frutas/index.html'));
  });

  test('a chunk embedded by a fallback backend is skipped, not stored',
      () async {
    write(
        'frutas/ruido.html', 'FLIP conteúdo que cai no fallback do embedding');
    final rag = await prepared();
    final r =
        await rag.contextFor('FLIP conteúdo fallback embedding', isLocal: true);
    expect(r.files.where((f) => f.endsWith('ruido.html')), isEmpty);
  });

  test('without registered projects the workspace is indexed as one', () async {
    File(p.join(tmp.path, '.shepherd', 'workspace.yaml'))
        .writeAsStringSync('workspace:\n  name: "ws"\n  projects: {}\n');
    final rag =
        AiSessionRag(workspaceRoot: tmp.path, embedding: _FakeEmbedding());
    final events = await rag.prepare().toList();
    expect(events.any((e) => e.data['project'] == '(workspace)'), isTrue);
    final r = await rag.contextFor('bolo de banana', isLocal: true);
    expect(r.chunks, greaterThan(0));
  });

  group('a selection never widens the search', () {
    /// A workspace where the projects are NOT registered in workspace.yaml.
    void unregister() => File(p.join(tmp.path, '.shepherd', 'workspace.yaml'))
        .writeAsStringSync('workspace:\n  name: "ws"\n  projects: {}\n');

    test('without registered projects, only the selected folder is searched',
        () async {
      unregister();
      final rag = await prepared(projects: ['oficina']);
      final banana = await rag.contextFor('receita de bolo de banana canela',
          isLocal: true);
      expect(banana.files.where((f) => f.contains('frutas')), isEmpty,
          reason: 'frutas was not selected: ${banana.files}');
      final trator =
          await rag.contextFor('manual do trator filtro diesel', isLocal: true);
      expect(trator.files,
          contains(predicate<String>((f) => f.contains('oficina'))));
    });

    test(
        'without registered projects and nothing selected, everything is searched',
        () async {
      unregister();
      final rag = await prepared();
      final r = await rag.contextFor('receita de bolo de banana canela',
          isLocal: true);
      expect(r.files.any((f) => f.contains('frutas')), isTrue);
    });

    test('a selection that matches nothing allows nothing, not everything',
        () async {
      final rag = await prepared(projects: ['nao-existe']);
      final r = await rag.contextFor('receita de bolo de banana canela',
          isLocal: true);
      expect(r.chunks, 0);
      expect(r.files, isEmpty);
    });

    test(
        'an unregistered folder selected in a curated manifest does not leak the others',
        () async {
      // frutas/oficina are registered; "extra" exists on disk but is not.
      write('extra/notas.md',
          'receita de bolo de banana com canela e açúcar mascavo');
      final rag = await prepared(projects: ['extra']);
      final r = await rag.contextFor('receita de bolo de banana canela',
          isLocal: true);
      expect(r.files.where((f) => f.startsWith('frutas/')), isEmpty);
    });

    test('registered projects are still matched by id, name or folder',
        () async {
      for (final sel in ['frutas', 'oficina']) {
        final rag = await prepared(projects: [sel]);
        final other = sel == 'frutas' ? 'oficina' : 'frutas';
        final r = await rag.contextFor(
            'receita de bolo de banana trator filtro diesel',
            isLocal: true);
        expect(r.files.where((f) => f.startsWith('$other/')), isEmpty,
            reason: sel);
      }
    });
  });

  test('runner adds retrieved context to the prompt and reports it', () async {
    final prompts = <String>[];
    final runner = AiSessionRunner(
      settings: const AiResolvedSettings(
          provider: 'ollama', model: 'm', isLocal: true),
      workspaceRoot: tmp.path,
      rag: AiSessionRag(workspaceRoot: tmp.path, embedding: _FakeEmbedding()),
      generate: (
          {required prompt,
          required provider,
          required model,
          apiKey,
          baseUrl,
          onUsage}) {
        prompts.add(prompt);
        return Stream.value('ok\n');
      },
    );
    final all = <AiEvent>[
      ...await runner.prepare().toList(),
      ...await runner.ask('como faço o bolo de banana?').toList(),
    ];
    final ctx = all.firstWhere((e) => e.type == 'rag_context');
    expect(ctx.data['files'], contains('frutas/index.html'));
    expect(prompts.single, contains('banana'));
    expect(all.last.type, 'done');
  });

  test('a file the AI wrote becomes searchable on the next question', () async {
    final runner = AiSessionRunner(
      settings: const AiResolvedSettings(
          provider: 'ollama', model: 'm', isLocal: true),
      workspaceRoot: tmp.path,
      rag: AiSessionRag(workspaceRoot: tmp.path, embedding: _FakeEmbedding()),
      generate: (
              {required prompt,
              required provider,
              required model,
              apiKey,
              baseUrl,
              onUsage}) =>
          Stream.value(
              '```html\n// FILE: frutas/novo.html\n<p>geleia de morango caseira</p>\n```\n'),
    );
    await runner.prepare().toList();
    final proposal = (await runner.ask('crie a pagina').toList())
        .firstWhere((e) => e.type == 'file_proposal');
    runner.confirm(proposal.data['id'] as String, approved: true);

    final next = await runner.ask('geleia de morango caseira').toList();
    final ctx = next.firstWhere((e) => e.type == 'rag_context');
    expect(ctx.data['files'], contains('frutas/novo.html'));
  });

  test('changing the selected projects keeps history and re-scopes retrieval',
      () async {
    final prompts = <String>[];
    final runner = AiSessionRunner(
      settings: const AiResolvedSettings(
          provider: 'ollama', model: 'm', isLocal: true),
      workspaceRoot: tmp.path,
      projects: ['oficina'],
      rag: AiSessionRag(
          workspaceRoot: tmp.path,
          projects: ['oficina'],
          embedding: _FakeEmbedding()),
      generate: (
          {required prompt,
          required provider,
          required model,
          apiKey,
          baseUrl,
          onUsage}) {
        prompts.add(prompt);
        return Stream.value('ok\n');
      },
    );
    await runner.prepare().toList();
    final before = await runner.ask('bolo de banana canela').toList();
    expect(before.where((e) => e.type == 'rag_context'), isEmpty);

    runner.setProjects(['frutas']);
    final after = await runner.ask('bolo de banana canela').toList();
    expect(after.firstWhere((e) => e.type == 'rag_context').data['files'],
        contains('frutas/index.html'));
    expect(prompts.last,
        contains('Usuário: bolo de banana canela')); // history kept
    expect(prompts.last, contains('trabalhando no projeto frutas'));
  });

  test('if RAG cannot run, the conversation still works', () async {
    final runner = AiSessionRunner(
      settings: const AiResolvedSettings(
          provider: 'ollama', model: 'm', isLocal: true),
      workspaceRoot: tmp.path,
      rag: AiSessionRag(
          workspaceRoot: '${tmp.path}/nao-existe',
          embedding: _ThrowingEmbedding()),
      generate: (
              {required prompt,
              required provider,
              required model,
              apiKey,
              baseUrl,
              onUsage}) =>
          Stream.value('oi\n'),
    );
    final prep = await runner.prepare().toList();
    expect(prep.single.type, 'rag_unavailable');
    final events = await runner.ask('oi').toList();
    expect(events.map((e) => e.type), containsAll(['text_delta', 'done']));
  });

  group('the company Wiki (.shepherd/wiki)', () {
    void wikiPage(String name, String text) =>
        write('.shepherd/wiki/$name', text);

    test('is indexed although .shepherd is a hidden folder', () async {
      wikiPage('calda.md',
          '# Calda bordalesa\n\nA calda bordalesa protege o pomar contra fungos no inverno.');
      final rag = await prepared();
      final r = await rag.contextFor('calda bordalesa pomar fungos inverno',
          isLocal: true);
      expect(
          r.files, contains(predicate<String>((f) => f.contains('calda.md'))));
    });

    test('is searched whatever projects are selected', () async {
      wikiPage('regra.md',
          '# Regra de colheita\n\nColher o mirtilo apenas no ponto ideal de maturação.');
      final rag = await prepared(projects: ['oficina']);
      final r = await rag.contextFor('colher mirtilo ponto ideal maturação',
          isLocal: true);
      expect(
          r.files, contains(predicate<String>((f) => f.contains('regra.md'))));
      // ...and the selection still holds for the projects themselves.
      final banana = await rag.contextFor('receita de bolo de banana canela',
          isLocal: true);
      expect(banana.files.where((f) => f.contains('frutas')), isEmpty);
    });

    test('a page removed from the folder is forgotten at the next sync',
        () async {
      wikiPage('some.md',
          '# Segredo\n\nInformação confidencial da empresa anterior sobre contratos.');
      var rag = await prepared();
      expect(
          (await rag.contextFor('informação confidencial contratos empresa',
                  isLocal: true))
              .files,
          isNotEmpty);

      Directory(p.join(tmp.path, '.shepherd', 'wiki'))
          .deleteSync(recursive: true);
      rag = await prepared();
      final r = await rag.contextFor(
          'informação confidencial contratos empresa',
          isLocal: true);
      expect(r.files.where((f) => f.contains('some.md')), isEmpty);
    });

    test('a workspace without a Wiki indexes exactly as before', () async {
      final rag = await prepared();
      final r = await rag.contextFor('receita de bolo de banana canela',
          isLocal: true);
      expect(r.files.any((f) => f.contains('frutas')), isTrue);
    });
  });
}

class _ThrowingEmbedding extends AiEmbeddingService {
  @override
  Future<List<double>> getEmbedding(String text, {AiConfigModel? config}) =>
      throw StateError('sem backend');
}
