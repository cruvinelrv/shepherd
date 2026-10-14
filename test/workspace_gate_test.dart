import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:shepherd/src/ai_client/session_reader.dart';
import 'package:shepherd/src/i18n/i18n.dart';
import 'package:shepherd/src/i18n/lang.dart';
import 'package:shepherd/src/tools/data/models/shell_session_model.dart';
import 'package:shepherd/src/tools/domain/services/union_workspace_service.dart';
import 'package:shepherd/src/tools/domain/services/workspace_manifest_service.dart';
import 'package:shepherd/src/tools/presentation/cli/workspace_gate.dart';
import 'package:test/test.dart';

const _login =
    LoginSession(token: 't', environment: 'prod', corporationId: 'c');

http.Client _union(Map<String, dynamic> data, {int status = 200}) =>
    MockClient((req) async {
      expect(req.headers['X-Auth-Token'], 't');
      expect(req.headers['X-Corporation-Id'], 'c');
      return http.Response(jsonEncode({'data': data}), status);
    });

void main() {
  late Directory dir;
  setUp(() {
    I18n.use(ShepherdLang.en);
    dir = Directory.systemTemp.createTempSync('gate_');
  });
  tearDown(() {
    I18n.reset();
    dir.deleteSync(recursive: true);
  });

  group('UnionWorkspaceService', () {
    test('reads the company workspace', () async {
      final ws = await UnionWorkspaceService(
          client: _union({
        'workspaceConfig': {'name': 'Acme', 'version': '2.0.0'},
        'projects': [
          {'id': '1'},
          {'id': '2'}
        ],
      })).fetch(_login);
      expect(ws!.name, 'Acme');
      expect(ws.version, '2.0.0');
      expect(ws.projectCount, 2);
    });

    test('a company with no workspace gives null', () async {
      final ws = await UnionWorkspaceService(
              client: _union({'workspaceConfig': null, 'projects': []}))
          .fetch(_login);
      expect(ws, isNull);
    });

    test('a refusal or an error becomes an exception', () {
      expect(
          UnionWorkspaceService(client: _union({}, status: 401)).fetch(_login),
          throwsA(isA<UnionWorkspaceException>()));
      final failing = MockClient((_) async => http.Response(
          jsonEncode({
            'errors': [
              {'message': 'Sessão inválida'}
            ]
          }),
          200));
      expect(UnionWorkspaceService(client: failing).fetch(_login),
          throwsA(predicate((e) => '$e'.contains('inválida'))));
    });

    test(
        'writes workspace.yaml with the Union name, never over an existing one',
        () {
      const ws = UnionWorkspace(name: 'Acme', version: '1.0.0');
      expect(UnionWorkspaceService.write(ws, dir), isTrue);
      expect(WorkspaceManifest.tryLoad(dir)!.name, 'Acme');
      expect(
          UnionWorkspaceService.write(
              const UnionWorkspace(name: 'Other', version: '1'), dir),
          isFalse);
      expect(WorkspaceManifest.tryLoad(dir)!.name, 'Acme');
    });
  });

  group('WorkspaceGate', () {
    WorkspaceGate gate(List<String?> answers, List<String> log,
        {LoginSession? session, http.Client? client}) {
      final it = answers.iterator;
      return WorkspaceGate(
        login: () async => log.add('login'),
        init: () async => log.add('init'),
        union: UnionWorkspaceService(client: client),
        readLine: () => it.moveNext() ? it.current : null,
        say: log.add,
        dir: dir,
        readLogin: (_) => session,
      );
    }

    test('offers the three ways to start and creates nothing by itself',
        () async {
      final log = <String>[];
      expect(await gate(['3'], log).run(), isTrue);
      final text = log.join('\n');
      expect(text, contains('Sign in'));
      expect(text, contains('new project'));
      expect(text, contains('without a workspace'));
      expect(Directory(p.join(dir.path, '.shepherd')).existsSync(), isFalse);
    });

    test('1: signs in and saves the Union workspace', () async {
      final log = <String>[];
      final ok = await gate(['1'], log,
          session: _login,
          client: _union({
            'workspaceConfig': {'name': 'Acme', 'version': '1.0.0'},
            'projects': [
              {'id': 'x'}
            ],
          })).run();
      expect(ok, isTrue);
      expect(log, contains('login'));
      expect(WorkspaceManifest.tryLoad(dir)!.name, 'Acme');
    });

    test('1 without a saved login goes back to the menu', () async {
      final log = <String>[];
      final ok = await gate(['1', '3'], log).run();
      expect(ok, isTrue);
      expect(log.join('\n'), contains('No login was saved'));
      expect(WorkspaceManifest.tryLoad(dir), isNull);
    });

    test('1 with no workspace in the Union says so and goes back', () async {
      final log = <String>[];
      await gate(['1', '3'], log,
          session: _login,
          client: _union({'workspaceConfig': null, 'projects': []})).run();
      expect(log.join('\n'), contains('no workspace set up'));
      expect(WorkspaceManifest.tryLoad(dir), isNull);
    });

    test('2 starts a new project', () async {
      final log = <String>[];
      expect(await gate(['2'], log).run(), isTrue);
      expect(log, contains('init'));
    });

    test('a wrong key asks again; the end of the input stops', () async {
      final log = <String>[];
      expect(await gate(['x', null], log).run(), isFalse);
      expect(log.join('\n'), contains('Type 1, 2 or 3'));
    });
  });

  group('ShellSessionModel without a workspace', () {
    test('does not take the folder name as the workspace', () {
      final old = Directory.current;
      final bare = Directory.systemTemp.createTempSync('bare_');
      try {
        Directory.current = bare;
        final s = ShellSessionModel.loadFromWorkspace();
        expect(s.workspaceName, isNull);
        expect(s.projectName, isEmpty);
      } finally {
        Directory.current = old;
        bare.deleteSync(recursive: true);
      }
    });
  });
}
