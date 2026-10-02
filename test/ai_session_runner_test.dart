import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shepherd/src/tools/domain/services/ai_jsonl_protocol.dart';
import 'package:shepherd/src/tools/domain/services/ai_session_runner.dart';
import 'package:shepherd/src/tools/domain/services/ai_settings_resolver.dart';
import 'package:shepherd/src/tools/presentation/commands/ai_jsonl_command.dart';
import 'package:test/test.dart';

const _settings = AiResolvedSettings(
  provider: 'ollama',
  model: 'm',
  isLocal: true,
);

AiGenerate _answer(List<String> chunks) => ({
      required prompt,
      required provider,
      required model,
      apiKey,
      baseUrl,
      onUsage,
    }) =>
        Stream.fromIterable(chunks);

const _reply = [
  'Criei o site.\n```html\n// FILE: ',
  'app/index.html\n<h1>oi</h1>\n```\n',
  'Pronto!\n',
];

void main() {
  late Directory tmp;
  late Directory previous;

  setUp(() {
    previous = Directory.current;
    tmp = Directory.systemTemp
        .createTempSync('ai_runner')
        .resolveSymbolicLinksSync()
        .let(Directory.new);
    Directory.current = tmp;
  });
  tearDown(() {
    Directory.current = previous;
    tmp.deleteSync(recursive: true);
  });

  AiSessionRunner runner({
    List<String> projects = const [],
    String mode = 'fast',
    List<String> chunks = _reply,
  }) =>
      AiSessionRunner(
        settings: _settings,
        workspaceRoot: tmp.path,
        projects: projects,
        mode: mode,
        generate: _answer(chunks),
      );

  test('prose is streamed without the file body; the file is only proposed',
      () async {
    final events = await runner().ask('crie um site').toList();
    final types = events.map((e) => e.type).toList();

    expect(types.first, 'text_delta');
    expect(types, contains('file_started'));
    expect(types.last, 'done');
    final prose = events
        .where((e) => e.type == 'text_delta')
        .map((e) => e.data['text'])
        .join();
    expect(prose, 'Criei o site.\nPronto!\n');

    final proposal = events.firstWhere((e) => e.type == 'file_proposal');
    expect(proposal.data['path'], 'app/index.html');
    expect(proposal.data['content'], contains('<h1>oi</h1>'));
    expect(proposal.data['is_new'], true);
    expect(File(p.join(tmp.path, 'app', 'index.html')).existsSync(), isFalse);
  });

  test('confirm writes the file once, and only when approved', () async {
    final r = runner();
    final proposal = (await r.ask('x').toList())
        .firstWhere((e) => e.type == 'file_proposal');
    final id = proposal.data['id'] as String;

    final result = r.confirm(id, approved: true);
    expect(result.data['applied'], true);
    expect(File(p.join(tmp.path, 'app', 'index.html')).readAsStringSync(),
        contains('<h1>oi</h1>'));
    expect(r.confirm(id, approved: true).type, 'error'); // already consumed

    final r2 = runner();
    final id2 = (await r2.ask('x').toList())
        .firstWhere((e) => e.type == 'file_proposal')
        .data['id'] as String;
    File(p.join(tmp.path, 'app', 'index.html')).deleteSync();
    expect(r2.confirm(id2, approved: false).data['applied'], false);
    expect(File(p.join(tmp.path, 'app', 'index.html')).existsSync(), isFalse);
  });

  test('selected projects fence off everything else, and so does the root',
      () async {
    final chunks = [
      '```x\n// FILE: app/ok.txt\n1\n```\n',
      '```x\n// FILE: other/no.txt\n2\n```\n',
      '```x\n// FILE: ../escape.txt\n3\n```\n',
      '```x\n// FILE: /etc/passwd\n4\n```\n',
    ];
    Directory(p.join(tmp.path, 'other')).createSync(); // another project
    final events =
        await runner(projects: ['app'], chunks: chunks).ask('x').toList();

    expect(
        events
            .where((e) => e.type == 'file_proposal')
            .map((e) => e.data['path']),
        ['app/ok.txt']);
    expect(
        events
            .where((e) => e.type == 'file_blocked')
            .map((e) => e.data['path']),
        ['other/no.txt', '../escape.txt', '/etc/passwd']);
    expect(
        events
            .where((e) => e.type == 'file_started')
            .map((e) => e.data['path']),
        ['app/ok.txt']);
  });

  group('paths written relative to the selected project', () {
    String lastPrompt = '';
    AiSessionRunner single(List<String> chunks,
            {List<String> projects = const ['app']}) =>
        AiSessionRunner(
          settings: _settings,
          workspaceRoot: tmp.path,
          projects: projects,
          generate: (
              {required prompt,
              required provider,
              required model,
              apiKey,
              baseUrl,
              onUsage}) {
            lastPrompt = prompt;
            return Stream.fromIterable(chunks);
          },
        );

    const fileBlock = '```dart\n// FILE: lib/main.dart\nvoid main() {}\n```\n';

    test(
        'with one project selected, lib/main.dart lands inside it (the case that was blocked)',
        () async {
      final events = await single([fileBlock]).ask('x').toList();
      final proposal = events.firstWhere((e) => e.type == 'file_proposal');
      expect(proposal.data['path'], 'app/lib/main.dart');
      expect(proposal.data['is_new'], true);
      expect(events.where((e) => e.type == 'file_blocked'), isEmpty);
      expect(events.firstWhere((e) => e.type == 'file_started').data['path'],
          'app/lib/main.dart');
    });

    test('a path already under the project is not nested twice', () async {
      final events =
          await single(['```dart\n// FILE: app/lib/main.dart\nx\n```\n'])
              .ask('x')
              .toList();
      expect(events.firstWhere((e) => e.type == 'file_proposal').data['path'],
          'app/lib/main.dart');
    });

    test('create vs modify is decided at the resolved location', () async {
      File(p.join(tmp.path, 'app', 'lib', 'main.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('antigo');
      final events = await single([fileBlock]).ask('x').toList();
      expect(events.firstWhere((e) => e.type == 'file_proposal').data['is_new'],
          false);
    });

    test('confirm writes into the project folder', () async {
      final r = single([fileBlock]);
      final id = (await r.ask('x').toList())
          .firstWhere((e) => e.type == 'file_proposal')
          .data['id'] as String;
      expect(r.confirm(id, approved: true).data['applied'], true);
      expect(File(p.join(tmp.path, 'app', 'lib', 'main.dart')).existsSync(),
          isTrue);
      expect(File(p.join(tmp.path, 'lib', 'main.dart')).existsSync(), isFalse);
    });

    test('an explicit path into another existing folder is still blocked',
        () async {
      Directory(p.join(tmp.path, 'loja')).createSync();
      final events = await single(['```x\n// FILE: loja/index.html\nx\n```\n'])
          .ask('x')
          .toList();
      expect(events.where((e) => e.type == 'file_proposal'), isEmpty);
      expect(events.firstWhere((e) => e.type == 'file_blocked').data['reason'],
          contains('fora dos projetos'));
    });

    test(
        'with several projects selected the path needs a project folder, and the notice says so',
        () async {
      final events = await single([fileBlock], projects: ['app', 'site'])
          .ask('x')
          .toList();
      expect(events.where((e) => e.type == 'file_proposal'), isEmpty);
      final reason = events
          .firstWhere((e) => e.type == 'file_blocked')
          .data['reason'] as String;
      expect(reason, contains('app, site'));
    });

    test('absolute paths and .. stay blocked whatever the selection', () async {
      final events = await single([
        '```x\n// FILE: /etc/passwd\nx\n```\n',
        '```x\n// FILE: ../fora.txt\nx\n```\n',
      ]).ask('x').toList();
      expect(events.where((e) => e.type == 'file_proposal'), isEmpty);
      expect(events.where((e) => e.type == 'file_blocked').length, 2);
    });

    test(
        'the prompt teaches the project-relative convention and forbids asking for approval in text',
        () async {
      await single([fileBlock]).ask('x').toList();
      expect(lastPrompt, contains('relativo à pasta do projeto app'));
      expect(lastPrompt, contains('NÃO peça aprovação por texto'));
      expect(lastPrompt, contains('Aplicar e Descartar'));

      await single([fileBlock], projects: ['a', 'b']).ask('x').toList();
      expect(lastPrompt, contains('começando pela pasta do projeto'));
    });
  });

  test('plan mode proposes nothing', () async {
    final events = await runner(mode: 'plan').ask('x').toList();
    expect(events.where((e) => e.type == 'file_proposal'), isEmpty);
    expect(events.last.type, 'done');
  });

  test('auto mode writes the file at once, with no confirm', () async {
    final events = await runner(mode: 'auto').ask('x').toList();
    final types = events.map((e) => e.type).toList();
    expect(types.indexOf('file_result'),
        types.indexOf('file_proposal') + 1); // result right after proposal
    expect(events.firstWhere((e) => e.type == 'file_result').data['applied'],
        true);
    expect(File(p.join(tmp.path, 'app', 'index.html')).readAsStringSync(),
        contains('<h1>oi</h1>'));
  });

  test('fast mode still waits for approval', () async {
    final events = await runner().ask('x').toList();
    expect(events.where((e) => e.type == 'file_result'), isEmpty);
    expect(File(p.join(tmp.path, 'app', 'index.html')).existsSync(), isFalse);
  });

  test('provider failures become typed error events', () async {
    final r = AiSessionRunner(
      settings: _settings,
      workspaceRoot: tmp.path,
      generate: (
              {required prompt,
              required provider,
              required model,
              apiKey,
              baseUrl,
              onUsage}) =>
          Stream.error(Exception('Connection refused (11434)')),
    );
    final events = await r.ask('x').toList();
    expect(events.single.type, 'error');
    expect(events.single.data['code'], 'ollama_offline');
  });

  test('history from earlier turns reaches the next prompt', () async {
    final prompts = <String>[];
    final r = AiSessionRunner(
      settings: _settings,
      workspaceRoot: tmp.path,
      generate: (
          {required prompt,
          required provider,
          required model,
          apiKey,
          baseUrl,
          onUsage}) {
        prompts.add(prompt);
        return Stream.value('resposta um\n');
      },
    );
    await r.ask('primeira pergunta').toList();
    await r.ask('segunda').toList();
    expect(prompts[1], contains('Usuário: primeira pergunta'));
    expect(prompts[1], contains('Assistente: resposta um'));
    expect(prompts[0], isNot(contains('Histórico Recente')));
  });

  test('jsonl session: ready, answer, proposal, confirm, bad lines ignored',
      () async {
    final input = StreamController<List<int>>();
    final out = <Map<String, dynamic>>[];
    final done = runAiJsonl(
      settings: _settings,
      mode: 'fast',
      tier: 'fast',
      projects: const [],
      input: input.stream,
      output: (l) => out.add(jsonDecode(l) as Map<String, dynamic>),
      generate: _answer(_reply),
      useRag: false,
    );
    void send(Map<String, dynamic> m) =>
        input.add(utf8.encode('${jsonEncode(m)}\n'));

    input.add(utf8.encode('lixo que não é json\n'));
    send({'type': 'user_message', 'text': 'crie um site'});
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final id = out.firstWhere((e) => e['type'] == 'file_proposal')['id'];
    send({'type': 'confirm', 'id': id, 'approved': true});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await input.close();
    await done;

    expect(out.first['type'], 'ready');
    expect(out.first['protocol'], aiJsonlProtocolVersion);
    expect(out.any((e) => e['type'] == 'done'), isTrue);
    expect(out.last['type'], 'file_result');
    expect(out.last['applied'], true);
    expect(File(p.join(tmp.path, 'app', 'index.html')).existsSync(), isTrue);
  });

  test('jsonl session refuses to start without credentials', () async {
    final out = <String>[];
    await runAiJsonl(
      settings: const AiResolvedSettings(
          provider: 'openai', model: 'gpt-4o', isLocal: false),
      mode: 'fast',
      tier: 'fast',
      projects: const [],
      input: const Stream.empty(),
      output: out.add,
      useRag: false,
    );
    expect(jsonDecode(out.single)['code'], 'not_configured');
    exitCode = 0;
  });
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
