import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shepherd/src/i18n/i18n.dart';
import 'package:shepherd/src/i18n/lang.dart';
import 'package:shepherd/src/init/presentation/cli/init/quick_init.dart';
import 'package:shepherd/src/init/presentation/cli/init/quick_init_git.dart';
import 'package:shepherd/src/tools/domain/services/workspace_manifest_service.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// A git that knows nothing, or what the test says (never touches the machine's).
GitProbe Function(String) fakeGit({
  bool repo = false,
  String? remote,
  String branch = 'main',
  String name = 'Ada Lovelace',
  String email = 'ada@example.com',
}) =>
    (dir) => GitProbe(dir, run: (exe, args, {workingDirectory}) async {
          String out = '';
          var code = 0;
          switch (args.first) {
            case '--version':
              out = 'git version 2.40';
            case 'rev-parse':
              out = repo ? 'true' : '';
              code = repo ? 0 : 128;
            case 'symbolic-ref':
              out = branch;
            case 'remote':
              out = remote ?? '';
              code = remote == null ? 2 : 0;
            case 'config':
              out = args.last == 'user.name' ? name : email;
          }
          return ProcessResult(0, code, out, '');
        });

void main() {
  late Directory root;
  late Directory old;
  setUp(() {
    I18n.use(ShepherdLang.en);
    old = Directory.current;
    root = Directory.systemTemp
        .createTempSync('qi_')
        .resolveSymbolicLinksSync()
        .let(Directory.new);
  });
  tearDown(() {
    Directory.current = old;
    I18n.reset();
    root.deleteSync(recursive: true);
  });

  QuickInitIO io(List<String> answers, [List<String>? log]) {
    final it = answers.iterator;
    return QuickInitIO(
      readLine: () => it.moveNext() ? it.current : '',
      say: (s) => log?.add(s),
      ask: (s) => log?.add(s),
    );
  }

  Map yamlOf(Directory d, String f) =>
      loadYaml(File(p.join(d.path, '.shepherd', f)).readAsStringSync()) as Map;

  test('Enter at every question: the standard workspace in this folder',
      () async {
    final folder = Directory(p.join(root.path, 'acme'))..createSync();
    final code = await runQuickInit([],
        io: io(['', '', '', '']), dir: folder, gitFor: fakeGit());
    expect(code, 0);
    expect(yamlOf(folder, 'project.yaml')['name'], 'acme');
    expect(yamlOf(folder, 'project.yaml')['init_mode'], 'full');
    expect(yamlOf(folder, 'environments.yaml'), {'PRD': 'main'});
    expect(WorkspaceManifest.tryLoad(folder)!.name, 'acme');
    final cfg = yamlOf(folder, 'config.yaml');
    expect(cfg.containsKey('repoType'), isFalse);
    expect(cfg['pullRequestEnabled'], false);
    expect(cfg.containsKey('project_id'), isFalse);
    expect(File(p.join(folder.path, '.shepherd', 'domains.yaml')).existsSync(),
        isTrue);
    expect(
        File(p.join(folder.path, '.shepherd', 'user_active.yaml'))
            .readAsStringSync(),
        contains('Ada'));
    expect(Directory(p.join(folder.path, 'devops')).existsSync(), isTrue);
    expect(Directory(p.join(folder.path, '.git')).existsSync(), isFalse,
        reason: 'a workspace folder is not a repository');
  });

  test('a different name offers a new folder, and takes it by default',
      () async {
    final folder = Directory(p.join(root.path, 'here'))..createSync();
    await runQuickInit([],
        io: io(['Shop', '', '', '', '']), dir: folder, gitFor: fakeGit());
    final created = Directory(p.join(folder.path, 'Shop'));
    expect(yamlOf(created, 'project.yaml')['name'], 'Shop');
    expect(Directory(p.join(folder.path, '.shepherd')).existsSync(), isFalse);
  });

  test('"n" keeps the folder and only names the workspace', () async {
    final folder = Directory(p.join(root.path, 'here'))..createSync();
    await runQuickInit([],
        io: io(['Shop', 'n', '', '', '']), dir: folder, gitFor: fakeGit());
    expect(yamlOf(folder, 'project.yaml')['name'], 'Shop');
    expect(Directory(p.join(folder.path, 'Shop')).existsSync(), isFalse);
  });

  test(
      'github: pull requests on, the username kept; the trunk is the repo\'s branch',
      () async {
    final folder = Directory(p.join(root.path, 'repo'))..createSync();
    await runQuickInit(['--repo', 'github', '--github', 'ada'],
        io: io(['', '', '']),
        dir: folder,
        gitFor: fakeGit(repo: true, branch: 'trunk'));
    expect(yamlOf(folder, 'config.yaml')['repoType'], 'github');
    expect(yamlOf(folder, 'config.yaml')['pullRequestEnabled'], true);
    expect(yamlOf(folder, 'environments.yaml'), {'PRD': 'trunk'});
  });

  test('a remote on Azure is detected and not asked', () async {
    final folder = Directory(p.join(root.path, 'az'))..createSync();
    final log = <String>[];
    await runQuickInit([],
        io: io(['', '', ''], log),
        dir: folder,
        gitFor:
            fakeGit(repo: true, remote: 'https://dev.azure.com/o/p/_git/r'));
    expect(yamlOf(folder, 'config.yaml')['repoType'], 'azure');
    expect(log.join(), isNot(contains('Where will the code live')));
  });

  test('--yes asks nothing and uses the defaults and flags', () async {
    final folder = Directory(p.join(root.path, 'ci'))..createSync();
    final log = <String>[];
    final code = await runQuickInit(
        ['--yes', '--name', 'ci', '--user', 'Bot Ci', '--email', 'b@x.io'],
        io: io([], log), dir: folder, gitFor: fakeGit(name: '', email: ''));
    expect(code, 0);
    expect(log.join(), isNot(contains('Workspace name')));
    expect(
        File(p.join(folder.path, '.shepherd', 'user_active.yaml'))
            .readAsStringSync(),
        contains('Bot'));
  });

  test('already initialised: --yes refuses, a "no" cancels', () async {
    final folder = Directory(p.join(root.path, 'twice'))..createSync();
    await runQuickInit(['--yes', '--user', 'A B'],
        io: io([]), dir: folder, gitFor: fakeGit());
    expect(
        await runQuickInit(['--yes'],
            io: io([]), dir: folder, gitFor: fakeGit()),
        1);
    expect(
        await runQuickInit([], io: io(['n']), dir: folder, gitFor: fakeGit()),
        1);
  });

  test('a name with a slash is refused', () async {
    final folder = Directory(p.join(root.path, 'bad'))..createSync();
    expect(
        await runQuickInit(['--yes', '--name', 'a/b'],
            io: io([]), dir: folder, gitFor: fakeGit()),
        1);
    expect(Directory(p.join(folder.path, '.shepherd')).existsSync(), isFalse);
  });
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
