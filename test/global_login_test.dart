import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shepherd/src/ai_client/session_reader.dart';
import 'package:test/test.dart';

void main() {
  late Directory home;
  late Directory folder;
  setUp(() {
    home = Directory.systemTemp.createTempSync('home_');
    folder = Directory.systemTemp.createTempSync('folder_');
  });
  tearDown(() {
    home.deleteSync(recursive: true);
    folder.deleteSync(recursive: true);
  });

  File local() => File(p.join(folder.path, '.shepherd', 'session.yaml'));

  test('a login saved for the computer is found from any folder', () {
    expect(LoginSession.read(folder, home), isNull);
    LoginSession.saveGlobal(
        token: 'tok',
        environment: 'uat',
        corporationId: 'c1',
        home: home,
        folder: folder);
    final s = LoginSession.read(folder, home)!;
    expect(s.token, 'tok');
    expect(s.environment, 'uat');
    expect(s.corporationId, 'c1');
    final other = Directory.systemTemp.createTempSync('other_');
    addTearDown(() => other.deleteSync(recursive: true));
    expect(LoginSession.read(other, home)!.token, 'tok');
    expect(local().existsSync(), isFalse,
        reason: 'login creates nothing in the folder');
  });

  test('a login a folder still has of its own wins, and login updates it', () {
    local().parent.createSync(recursive: true);
    local().writeAsStringSync('token: old\nenv: prod\n');
    LoginSession.saveGlobal(
        token: 'old', environment: 'prod', home: home, folder: folder);
    LoginSession.saveGlobal(
        token: 'new', environment: 'prod', home: home, folder: folder);
    expect(LoginSession.read(folder, home)!.token, 'new');
    expect(LoginSession.globalFile(home: home).readAsStringSync(),
        contains('new'));
  });

  test('saving keeps the other things in the global file', () {
    final g = LoginSession.globalFile(home: home);
    g.parent.createSync(recursive: true);
    g.writeAsStringSync('personId: "p9"\ntoken: a\n');
    LoginSession.saveGlobal(
        token: 'b', environment: 'prod', home: home, folder: folder);
    final s = LoginSession.read(folder, home)!;
    expect(s.token, 'b');
    expect(s.personId, 'p9');
  });

  test('only the user can read the global file', () {
    LoginSession.saveGlobal(
        token: 't', environment: 'prod', home: home, folder: folder);
    if (Platform.isWindows) return;
    final mode = LoginSession.globalFile(home: home).statSync().mode & 511;
    expect(mode, 384); // 0600
  });

  test('the project link still comes from the folder', () {
    LoginSession.saveGlobal(
        token: 't', environment: 'prod', home: home, folder: folder);
    File(p.join(folder.path, '.shepherd', 'config.yaml'))
      ..createSync(recursive: true)
      ..writeAsStringSync('project_id: "proj-1"\n');
    expect(LoginSession.read(folder, home)!.projectId, 'proj-1');
  });
}
