import 'dart:io';

import 'package:shepherd/src/ai_client/rpc_client.dart';
import 'package:shepherd/src/ai_client/session_reader.dart';
import 'package:test/test.dart';

Future<RpcClient> _start() => RpcClient.start(Platform.resolvedExecutable,
    args: ['run', 'test/fixtures/fake_engine.dart']);

void main() {
  test(
      'initializes, streams the answer as notifications and returns the result',
      () async {
    final c = await _start();
    addTearDown(c.close);
    final init =
        await c.request('initialize', {'protocolVersion': 2, 'mode': 'auto'});
    expect(init['session']['mode'], 'auto');

    final deltas = <String>[];
    final sub = c.notifications
        .where((n) => n.method == 'session/textDelta')
        .listen((n) => deltas.add(n.params['text'] as String));
    final result = await c.request('session/send', {'text': 'mundo'});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(deltas.join(), 'Olá, mundo');
    expect(result['stopReason'], 'complete');
    expect(result['usage']['promptTokens'], 10);
  });

  test('a JSON-RPC error becomes an RpcException with the stable code',
      () async {
    final c = await _start();
    addTearDown(c.close);
    await c.request('initialize', {'protocolVersion': 2});
    await expectLater(
      c.request('session/send', {'text': 'erro'}),
      throwsA(isA<RpcException>()
          .having((e) => e.stableCode, 'stableCode', 'model_unavailable')
          .having((e) => e.data['model'], 'model', 'm')),
    );
  });

  test('a single huge line (a whole file) arrives intact', () async {
    final c = await _start();
    addTearDown(c.close);
    await c.request('initialize', {'protocolVersion': 2});
    final got = <String>[];
    final sub = c.notifications
        .where((n) => n.method == 'session/textDelta')
        .listen((n) => got.add(n.params['text'] as String));
    await c.request('session/send', {'text': 'grande'});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await sub.cancel();
    expect(got.single.length, 200000);
  });

  test('when the engine dies, pending requests fail instead of hanging',
      () async {
    final c = await _start();
    await c.request('initialize', {'protocolVersion': 2});
    final pending =
        c.request('session/send', {'text': 'oi'}); // answered, but then...
    await pending;
    final lost =
        c.request('nao_existe_no_fake'); // the fake never answers this one
    c.notify('exit');
    await expectLater(
        lost,
        throwsA(isA<RpcException>()
            .having((e) => e.stableCode, 'stableCode', 'engine_exited')));
  });

  group('login session', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('login_'));
    tearDown(() => dir.deleteSync(recursive: true));

    void write(String rel, String text) {
      final f = File('${dir.path}/$rel')..createSync(recursive: true);
      f.writeAsStringSync(text);
    }

    test('reads the token, environment, company, person and linked project',
        () {
      write('.shepherd/session.yaml',
          'token: abc\nenv: uat\ncorporationId: c1\npersonId: p1\n');
      write('.shepherd/config.yaml', 'project_id: proj9\n');
      final s = LoginSession.read(dir, dir)!;
      expect(s.toAuth(), {
        'token': 'abc',
        'environment': 'uat',
        'corporationId': 'c1',
        'personId': 'p1',
        'projectId': 'proj9'
      });
    });

    test('nobody logged in: null', () {
      expect(LoginSession.read(dir, dir), isNull);
      write('.shepherd/session.yaml', 'token: ""\n');
      expect(LoginSession.read(dir, dir), isNull);
    });
  });
}
