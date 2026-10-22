import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:shepherd/src/ai_client/ai_launcher.dart';
import 'package:shepherd/src/ai_client/session_reader.dart';
import 'package:shepherd/src/i18n/i18n.dart';
import 'package:shepherd/src/tools/data/models/shell_session_model.dart';
import 'package:shepherd/src/tools/domain/services/union_workspace_service.dart';
import 'package:shepherd/src/tools/domain/services/workspace_manifest_service.dart';
import 'package:shepherd/src/tools/presentation/cli/workspace_gate.dart';
import 'package:test/test.dart';

const _login = LoginSession(token: 't', environment: 'prod', corporationId: 'c');

http.Client _union(Map<String, dynamic> data, {int status = 200}) => MockClient((req) async {
      expect(req.headers['X-Auth-Token'], 't');
      expect(req.headers['X-Corporation-Id'], 'c');
      return http.Response(jsonEncode({'data': data}), status);
    });

void main() {
  placeholderTests();
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
      final ws =
          await UnionWorkspaceService(client: _union({'workspaceConfig': null, 'projects': []}))
              .fetch(_login);
      expect(ws, isNull);
    });

    test('a refusal or an error becomes an exception', () {
      expect(UnionWorkspaceService(client: _union({}, status: 401)).fetch(_login),
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

    test('writes workspace.yaml with the Union name, never over an existing one', () {
      const ws = UnionWorkspace(name: 'Acme', version: '1.0.0');
      expect(UnionWorkspaceService.write(ws, dir), isTrue);
      expect(WorkspaceManifest.tryLoad(dir)!.name, 'Acme');
      expect(UnionWorkspaceService.write(const UnionWorkspace(name: 'Other', version: '1'), dir),
          isFalse);
      expect(WorkspaceManifest.tryLoad(dir)!.name, 'Acme');
    });
  });

  group('WorkspaceGate', () {
    /// [loggedIn]: already signed in; [loginWorks]: what `login` does when asked.
    WorkspaceGate gate(List<String?> answers, List<String> log,
        {bool loggedIn = true, bool loginWorks = true, http.Client? client}) {
      final it = answers.iterator;
      LoginSession? session = loggedIn ? _login : null;
      return WorkspaceGate(
        login: () async {
          log.add('login');
          if (loginWorks) session = _login;
        },
        init: () async => log.add('init'),
        union: UnionWorkspaceService(client: client),
        readLine: () => it.moveNext() ? it.current : null,
        say: log.add,
        dir: dir,
        readLogin: (_) => session,
      );
    }

    test('offers the company workspace, a new one, the dev tools or leaving; creates nothing',
        () async {
      final log = <String>[];
      expect(await gate(['4'], log).run(), isFalse);
      final text = log.join('\n');
      expect(text, contains("company's workspace"));
      expect(text, contains('new workspace'));
      expect(text, contains('dev tools'));
      expect(text, contains('Exit'));
      expect(log, isNot(contains('login')), reason: 'nothing forces a login');
      expect(Directory(p.join(dir.path, '.shepherd')).existsSync(), isFalse);
    });

    test('the dev tools need no account and no workspace', () async {
      final log = <String>[];
      expect(await gate(['3'], log, loggedIn: false).run(), isTrue);
      expect(log, isNot(contains('login')));
      expect(WorkspaceManifest.tryLoad(dir), isNull);
    });

    test('1 not signed in: signs in first, then takes the workspace', () async {
      final log = <String>[];
      final ok = await gate(['1'], log,
          loggedIn: false,
          client: _union({
            'workspaceConfig': {'name': 'Acme', 'version': '1.0.0'},
            'projects': <Object>[],
          })).run();
      expect(ok, isTrue);
      expect(log, contains('login'));
      expect(WorkspaceManifest.tryLoad(dir)!.name, 'Acme');
    });

    test('1 with a login that fails: offered again, "n" goes back to the menu', () async {
      final log = <String>[];
      final ok = await gate(['1', 'n', '4'], log, loggedIn: false, loginWorks: false).run();
      expect(ok, isFalse);
      expect(log.where((l) => l == 'login'), hasLength(1));
      expect(log.join('\n'), contains('No login was saved'));
    });

    test('1: takes the Union workspace and saves it', () async {
      final log = <String>[];
      final ok = await gate(['1'], log,
          client: _union({
            'workspaceConfig': {'name': 'Acme', 'version': '1.0.0'},
            'projects': [
              {'id': 'x'}
            ],
          })).run();
      expect(ok, isTrue);
      expect(log, isNot(contains('login')), reason: 'already signed in');
      expect(WorkspaceManifest.tryLoad(dir)!.name, 'Acme');
    });

    test('1 with no workspace in the Union says so and goes back to the menu', () async {
      final log = <String>[];
      final ok =
          await gate(['1', '4'], log, client: _union({'workspaceConfig': null, 'projects': []}))
              .run();
      expect(ok, isFalse);
      expect(log.join('\n'), contains('no workspace set up'));
      expect(WorkspaceManifest.tryLoad(dir), isNull);
    });

    test('2 starts a new workspace; without a login it offers one first, and "n" skips it',
        () async {
      final log = <String>[];
      expect(await gate(['2', 'n'], log, loggedIn: false).run(), isTrue);
      expect(log, contains('init'));
      expect(log, isNot(contains('login')));
      final again = <String>[];
      expect(await gate(['2', ''], again, loggedIn: false).run(), isTrue);
      expect(again.indexOf('login'), lessThan(again.indexOf('init')));
    });

    test('a wrong key asks again; the end of the input stops', () async {
      final log = <String>[];
      expect(await gate(['x', null], log).run(), isFalse);
      expect(log.join('\n'), contains('Type 1, 2, 3 or 4'));
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

void placeholderTests() {
  group('a workspace.yaml that is not a workspace', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('ph_'));
    tearDown(() => root.deleteSync(recursive: true));

    File ws(Directory d, String body) {
      final f = File(p.join(d.path, '.shepherd', 'workspace.yaml'));
      f.parent.createSync(recursive: true);
      return f..writeAsStringSync(body);
    }

    test('the empty one an older version wrote, named after the folder', () {
      final d = Directory(p.join(root.path, 'myfolder'))..createSync();
      ws(d, '''workspace:
  name: "myfolder"
  version: "1.0.0"
  team_members: []
  squads: []
  projects: {}
''');
      expect(WorkspaceManifest.tryLoad(d), isNull);
    });

    test('one with content, or a different name, is a workspace', () {
      final d = Directory(p.join(root.path, 'a'))..createSync();
      ws(d, 'workspace:\n  name: "Acme"\n  projects: {}\n');
      expect(WorkspaceManifest.tryLoad(d)!.name, 'Acme');
      final e = Directory(p.join(root.path, 'b'))..createSync();
      ws(e, 'workspace:\n  name: "b"\n  team_members: [x]\n  projects: {}\n');
      expect(WorkspaceManifest.tryLoad(e)!.name, 'b');
    });

    test('the Union\'s workspace counts even if it has the folder\'s name', () {
      final d = Directory(p.join(root.path, 'acme'))..createSync();
      UnionWorkspaceService.write(const UnionWorkspace(name: 'acme', version: '1.0.0'), d);
      expect(WorkspaceManifest.tryLoad(d)!.name, 'acme');
    });
  });

  test('the shell can hand a tier to ai without breaking its options', () {
    final r = createAiParser()
        .parse(['hello', '--mode', 'fast', '--tier', 'fast', '--profile', 'medium']);
    expect(r.rest, ['hello']);
  });
}
