import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shepherd/src/tools/domain/entities/update_entities.dart';
import 'package:shepherd/src/tools/domain/services/install_method_detector.dart';
import 'package:shepherd/src/tools/domain/services/latest_version_service.dart';
import 'package:shepherd/src/tools/presentation/commands/update_command.dart';
import 'package:test/test.dart';

void main() {
  group('InstallMethodDetector', () {
    InstallMethod detect(String exe, {String script = '/x/bin/shepherd'}) =>
        InstallMethodDetector.detect(executable: exe, script: script);

    test('recognises each way of installing', () {
      expect(
          detect(
              '/opt/homebrew/Cellar/shepherd_cli/0.13.0/libexec/bin/shepherd'),
          InstallMethod.homebrew);
      expect(
          detect(
              '/home/linuxbrew/.linuxbrew/Cellar/shepherd_cli/0.13.0/libexec/bin/shepherd'),
          InstallMethod.homebrew);
      expect(detect('/Users/v/.shepherd/bin/shepherd'),
          InstallMethod.installScript);
      // HOME behind a symlink (macOS /tmp -> /private/tmp) still counts.
      expect(detect('/private/tmp/h/.shepherd/bin/shepherd'),
          InstallMethod.installScript);
      expect(detect(r'C:\Users\v\.shepherd\bin\shepherd.exe'),
          InstallMethod.installScript);
      expect(
          detect('/opt/homebrew/bin/dart',
              script:
                  '/Users/v/.pub-cache/global_packages/shepherd/bin/shepherd.dart-3.9.snapshot'),
          InstallMethod.pubGlobal);
      expect(
          detect(
              '/Applications/Shepherd Studio.app/Contents/Frameworks/App.framework/Versions/A/'
              'Resources/flutter_assets/assets/shepherd_cli/bin/shepherd'),
          InstallMethod.studioBundled);
      expect(
          detect('/usr/local/bin/dart',
              script: '/work/shepherd/bin/shepherd.dart'),
          InstallMethod.source);
      expect(detect('/somewhere/odd/shepherd'), InstallMethod.unknown);
    });

    test(
        'a Dart SDK from Homebrew does not make a pub.dev install look like Homebrew',
        () {
      expect(
          detect('/opt/homebrew/Cellar/dart/3.9.0/libexec/bin/dart',
              script:
                  '/Users/v/.pub-cache/global_packages/shepherd/bin/shepherd.dart-3.9.snapshot'),
          InstallMethod.pubGlobal);
      // ...and running from a checkout with that same SDK is "source", not Homebrew.
      expect(
          detect('/opt/homebrew/Cellar/dart/3.9.0/libexec/bin/dart',
              script: '/work/shepherd/bin/shepherd.dart'),
          InstallMethod.source);
    });

    test(
        'the Homebrew command uses the formula name, pub uses the package name',
        () {
      expect(InstallMethodDetector.updateCommand(InstallMethod.homebrew),
          'brew update && brew upgrade shepherd_cli');
      expect(InstallMethodDetector.updateCommand(InstallMethod.pubGlobal),
          'dart pub global activate shepherd');
      expect(InstallMethodDetector.updateCommand(InstallMethod.installScript),
          contains('install.sh'));
      expect(
          InstallMethodDetector.updateCommand(InstallMethod.installScript,
              windows: true),
          contains('install.ps1'));
      expect(InstallMethodDetector.updateCommand(InstallMethod.studioBundled),
          isNull);
    });
  });

  group('versions', () {
    test('compares numerically, never claims an update from nonsense', () {
      expect(compareVersions('0.13.0', '0.12.24'), greaterThan(0));
      expect(compareVersions('0.12.9', '0.12.10'),
          lessThan(0)); // not a string compare
      expect(compareVersions('v1.0.0', '1.0.0'), 0);
      expect(compareVersions('0.13.0-dev', '0.13.0'), 0);
      expect(compareVersions('abc', '0.13.0'), 0);
    });

    test('a newer local build is not an "update"', () {
      expect(
          const PackageVersionEntity(current: '0.13.1', latest: '0.13.0')
              .hasUpdate,
          isFalse);
      expect(
          const PackageVersionEntity(current: '0.13.0', latest: '0.13.1')
              .hasUpdate,
          isTrue);
    });
  });

  group('LatestVersionService', () {
    LatestVersionService svc(http.Client c) => LatestVersionService(client: c);

    test(
        'Homebrew/script installs follow the GitHub release; pub follows pub.dev',
        () async {
      final urls = <String>[];
      final client = MockClient((r) async {
        urls.add(r.url.host);
        return r.url.host == 'api.github.com'
            ? http.Response(jsonEncode({'tag_name': 'v0.13.5'}), 200)
            : http.Response(
                jsonEncode({
                  'latest': {'version': '0.13.2'}
                }),
                200);
      });
      expect(await svc(client).latestFor(InstallMethod.homebrew), '0.13.5');
      expect(await svc(client).latestFor(InstallMethod.pubGlobal), '0.13.2');
      expect(urls, ['api.github.com', 'pub.dev']);
    });

    test('failures yield null instead of throwing', () async {
      expect(
          await svc(MockClient((_) async => http.Response('nope', 500)))
              .latestFor(InstallMethod.homebrew),
          isNull);
      expect(
          await svc(MockClient(
                  (_) async => throw http.ClientException('offline')))
              .latestFor(InstallMethod.homebrew),
          isNull);
      expect(
          await svc(MockClient((_) async => http.Response('[]', 200)))
              .latestFor(InstallMethod.homebrew),
          isNull);
    });
  });

  group('shepherd update', () {
    Future<({int code, List<String> out, List<String> ran})> go(
      List<String> args, {
      required InstallMethod method,
      String latest = '0.14.0',
      String current = '0.13.0',
      bool answer = false,
      Future<int> Function(String)? runner,
    }) async {
      final out = <String>[];
      final ran = <String>[];
      final code = await runUpdateCommand(
        args,
        method: method,
        currentVersion: current,
        latest: LatestVersionService(
          client: MockClient((r) async => r.url.host == 'api.github.com'
              ? http.Response(jsonEncode({'tag_name': 'v$latest'}), 200)
              : http.Response(
                  jsonEncode({
                    'latest': {'version': latest}
                  }),
                  200)),
        ),
        out: out.add,
        confirm: () => answer,
        run: (c) async {
          ran.add(c);
          return runner == null ? 0 : await runner(c);
        },
        windows: false,
      );
      return (code: code, out: out, ran: ran);
    }

    String joined(List<String> o) => o.join('\n');

    test('up to date: says so and runs nothing', () async {
      final r = await go([], method: InstallMethod.homebrew, latest: '0.13.0');
      expect(r.code, 0);
      expect(joined(r.out), contains('já está na versão mais recente'));
      expect(r.ran, isEmpty);
    });

    test('Homebrew: shows the brew command and does not run it without a yes',
        () async {
      final r = await go([], method: InstallMethod.homebrew, answer: false);
      expect(
          joined(r.out), contains('brew update && brew upgrade shepherd_cli'));
      expect(joined(r.out), isNot(contains('dart pub global')));
      expect(r.ran, isEmpty);
    });

    test('--check never runs anything, even with --yes', () async {
      final r = await go(['--check', '--yes'], method: InstallMethod.homebrew);
      expect(r.ran, isEmpty);
    });

    test('--yes runs the Homebrew command; a failure is reported with exit 1',
        () async {
      final ok = await go(['--yes'], method: InstallMethod.homebrew);
      expect(ok.ran, ['brew update && brew upgrade shepherd_cli']);
      expect(ok.code, 0);

      final bad = await go(['--yes'],
          method: InstallMethod.homebrew, runner: (_) async => 1);
      expect(bad.code, 1);
      expect(joined(bad.out), contains('falhou'));
    });

    test('answering yes runs the pub command for a pub install', () async {
      final r = await go([], method: InstallMethod.pubGlobal, answer: true);
      expect(r.ran, ['dart pub global activate shepherd']);
    });

    test('a script install is shown, never run (it is a piped installer)',
        () async {
      final r = await go(['--yes'], method: InstallMethod.installScript);
      expect(joined(r.out), contains('install.sh'));
      expect(r.ran, isEmpty);
    });

    test('Studio bundle and source checkout get guidance, not a command',
        () async {
      final studio = await go(['--yes'], method: InstallMethod.studioBundled);
      expect(joined(studio.out), contains('atualize o Studio'));
      final src = await go(['--yes'], method: InstallMethod.source);
      expect(joined(src.out), contains('git pull'));
      expect(studio.ran, isEmpty);
      expect(src.ran, isEmpty);
    });

    test('unknown install lists every option', () async {
      final r = await go([], method: InstallMethod.unknown);
      final text = joined(r.out);
      expect(text, contains('brew update && brew upgrade shepherd_cli'));
      expect(text, contains('dart pub global activate shepherd'));
      expect(text, contains('install.sh'));
      expect(r.ran, isEmpty);
    });

    test('no network: explains and exits 1', () async {
      final out = <String>[];
      final code = await runUpdateCommand(
        const [],
        method: InstallMethod.homebrew,
        currentVersion: '0.13.0',
        latest: LatestVersionService(
            client:
                MockClient((_) async => throw http.ClientException('offline'))),
        out: out.add,
      );
      expect(code, 1);
      expect(out.join('\n'), contains('Não consegui consultar'));
    });
  });
}
