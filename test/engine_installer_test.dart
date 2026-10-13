import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:shepherd/src/ai_client/engine_config.dart';
import 'package:shepherd/src/ai_client/engine_installer.dart';
import 'package:shepherd/src/ai_client/engine_manifest.dart';
import 'package:test/test.dart';

const _feedUrl = 'https://example.com/releases/ai/latest.json';

/// A fake engine: a shell script that answers `--version` like the real one.
List<int> _fakeEngineScript(String version) =>
    utf8.encode('#!/bin/sh\necho "shepherd_ai $version (protocol 2)"\n');

List<int> _tarGz(List<int> binary) {
  final archive = Archive()
    ..addFile(ArchiveFile(EngineConfig.exeName, binary.length, binary))
    ..addFile(ArchiveFile('../evil.sh', 3, utf8.encode('rm\n')));
  return GZipEncoder().encode(TarEncoder().encode(archive));
}

class _Feed {
  final ed.KeyPair keys = ed.generateKey();
  late final String publicKey = base64.encode(keys.publicKey.bytes);

  /// A client that serves a feed for [version] with [binary] packed as the package.
  MockClient client(String version, List<int> binary,
      {bool badSignature = false,
      bool badHash = false,
      bool offline = false,
      void Function(String)? onGet}) {
    final pkg = _tarGz(binary);
    final feed = utf8.encode(jsonEncode({
      'version': version,
      'published': '2026-10-14T00:00:00Z',
      'notes': '',
      'platforms': {
        'linux-x64': {
          'url':
              'https://example.com/releases/ai/shepherd_ai-$version-linux-x64.tar.gz',
          'sha256': badHash ? 'a' * 64 : sha256.convert(pkg).toString(),
          'size': pkg.length,
        },
      },
    }));
    final signed = badSignature
        ? Uint8List.fromList(utf8.encode('{"tampered":true}'))
        : Uint8List.fromList(feed);
    final sig = base64.encode(ed.sign(keys.privateKey, signed));
    return MockClient((req) async {
      onGet?.call(req.url.toString());
      if (offline) throw const SocketException('no network');
      final url = req.url.toString();
      if (url == _feedUrl) return http.Response.bytes(feed, 200);
      if (url == '$_feedUrl.sig') return http.Response(sig, 200);
      if (url.endsWith('.tar.gz')) return http.Response.bytes(pkg, 200);
      return http.Response('not found', 404);
    });
  }
}

void main() {
  late Directory dir;
  late _Feed feed;

  EngineInstaller installer(http.Client client, {DateTime Function()? now}) =>
      EngineInstaller(
        client: client,
        manifestUrl: _feedUrl,
        publicKey: feed.publicKey,
        platformKey: 'linux-x64',
        installDir: dir,
        now: now,
      );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('engine_install_');
    feed = _Feed();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test(
      'installs the engine from a signed feed and only that file from the archive',
      () async {
    final exe =
        await installer(feed.client('0.1.0', _fakeEngineScript('0.1.0')))
            .ensure();
    expect(exe.path, p.join(dir.path, EngineConfig.exeName));
    expect(exe.existsSync(), isTrue);
    expect(File(p.join(dir.parent.path, 'evil.sh')).existsSync(), isFalse);
    expect(
        await installer(feed.client('0.1.0', _fakeEngineScript('0.1.0')))
            .installedVersion(exe),
        EngineVersion.tryParse('0.1.0'));
    if (!Platform.isWindows)
      expect(exe.statSync().mode & 0x40, isNot(0),
          reason: 'must be executable');
  });

  test('refuses a feed whose signature does not match, and installs nothing',
      () async {
    final i = installer(
        feed.client('0.1.0', _fakeEngineScript('0.1.0'), badSignature: true));
    await expectLater(
        i.ensure(),
        throwsA(isA<EngineInstallException>()
            .having((e) => e.message, 'message', contains('assinatura'))));
    expect(File(p.join(dir.path, EngineConfig.exeName)).existsSync(), isFalse);
  });

  test("refuses a feed signed with someone else's key", () async {
    final other = _Feed();
    final i = EngineInstaller(
      client: other.client('0.1.0', _fakeEngineScript('0.1.0')),
      manifestUrl: _feedUrl,
      publicKey:
          feed.publicKey, // the CLI trusts `feed`, the host signs with `other`
      platformKey: 'linux-x64',
      installDir: dir,
    );
    await expectLater(i.ensure(), throwsA(isA<EngineInstallException>()));
  });

  test('refuses a package whose hash is not the one in the signed feed',
      () async {
    final i = installer(
        feed.client('0.1.0', _fakeEngineScript('0.1.0'), badHash: true));
    await expectLater(
        i.ensure(),
        throwsA(isA<EngineInstallException>()
            .having((e) => e.message, 'message', contains('hash'))));
    expect(File(p.join(dir.path, EngineConfig.exeName)).existsSync(), isFalse);
  });

  test(
      'updates when the feed has a newer version, and leaves the engine alone otherwise',
      () async {
    await installer(feed.client('0.1.0', _fakeEngineScript('0.1.0'))).ensure();
    var gets = <String>[];
    // Same version again (forced check): no download.
    await installer(
            feed.client('0.1.0', _fakeEngineScript('0.1.0'), onGet: gets.add))
        .ensure(force: true);
    expect(gets.where((u) => u.endsWith('.tar.gz')), isEmpty);
    // A newer one: downloaded and swapped in.
    gets = [];
    final exe = await installer(
            feed.client('0.2.0', _fakeEngineScript('0.2.0'), onGet: gets.add))
        .ensure(force: true);
    expect(gets.where((u) => u.endsWith('.tar.gz')), hasLength(1));
    expect(
        await installer(feed.client('0.2.0', _fakeEngineScript('0.2.0')))
            .installedVersion(exe),
        EngineVersion.tryParse('0.2.0'));
  });

  test('looks at the feed at most every few hours', () async {
    await installer(feed.client('0.1.0', _fakeEngineScript('0.1.0'))).ensure();
    final gets = <String>[];
    var clock = DateTime.now();
    await installer(
        feed.client('0.1.0', _fakeEngineScript('0.1.0'), onGet: gets.add),
        now: () => clock).ensure();
    expect(gets, isEmpty, reason: 'just checked: no request');
    clock = clock.add(const Duration(hours: 7));
    await installer(
        feed.client('0.1.0', _fakeEngineScript('0.1.0'), onGet: gets.add),
        now: () => clock).ensure();
    expect(gets, isNotEmpty);
  });

  test(
      'offline: keeps using the installed engine, but fails clearly when there is none',
      () async {
    await installer(feed.client('0.1.0', _fakeEngineScript('0.1.0'))).ensure();
    final exe = await installer(
            feed.client('0.1.0', _fakeEngineScript('0.1.0'), offline: true))
        .ensure(force: true);
    expect(exe.existsSync(), isTrue);

    final empty = Directory.systemTemp.createTempSync('engine_empty_');
    addTearDown(() => empty.deleteSync(recursive: true));
    final i = EngineInstaller(
      client: feed.client('0.1.0', _fakeEngineScript('0.1.0'), offline: true),
      manifestUrl: _feedUrl,
      publicKey: feed.publicKey,
      platformKey: 'linux-x64',
      installDir: empty,
    );
    await expectLater(
        i.ensure(),
        throwsA(isA<EngineInstallException>()
            .having((e) => e.message, 'message', contains('internet'))));
  });

  test('no package for this platform says so', () async {
    final i = EngineInstaller(
      client: feed.client('0.1.0', _fakeEngineScript('0.1.0')),
      manifestUrl: _feedUrl,
      publicKey: feed.publicKey,
      platformKey: 'macos-x64',
      installDir: dir,
    );
    await expectLater(
        i.ensure(),
        throwsA(isA<EngineInstallException>()
            .having((e) => e.message, 'message', contains('macos-x64'))));
  });

  group('manifest', () {
    test('ignores packages that are not https or have no real hash', () {
      final m = EngineManifest.parse(jsonEncode({
        'version': '1.2.3',
        'platforms': {
          'ok': {'url': 'https://x/a.tar.gz', 'sha256': 'b' * 64, 'size': 5},
          'http': {'url': 'http://x/a.tar.gz', 'sha256': 'b' * 64},
          'nohash': {'url': 'https://x/a.tar.gz', 'sha256': 'nope'},
        },
      }));
      expect(m.packages.keys, ['ok']);
      expect(
          () => EngineManifest.parse('{"version":"x"}'), throwsFormatException);
      expect(() => EngineManifest.parse('nope'), throwsFormatException);
    });

    test('versions compare as numbers', () {
      expect(
          EngineVersion.tryParse('0.10.0')! > EngineVersion.tryParse('0.9.9')!,
          isTrue);
      expect(EngineVersion.tryParse('v1.0.0'), EngineVersion.tryParse('1.0.0'));
      expect(EngineVersion.tryParse('1.0'), isNull);
    });
  });
}
