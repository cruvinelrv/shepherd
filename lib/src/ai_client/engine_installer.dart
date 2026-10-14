import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../i18n/i18n.dart';
import 'engine_config.dart';
import 'engine_manifest.dart';

class EngineInstallException implements Exception {
  final String message;
  const EngineInstallException(this.message);
  @override
  String toString() => message;
}

/// Finds the engine on this computer, and installs or updates it from the feed.
///
/// Trust: the feed must carry a valid Ed25519 signature, and a package must
/// match the SHA-256 the (signed) feed lists. Anything else is refused and
/// nothing is installed.
class EngineInstaller {
  final http.Client _client;
  final String manifestUrl;
  final String publicKey;
  final String? platformKey;
  final Directory installDir;
  final Duration checkEvery;
  final DateTime Function() _now;
  final void Function(String message)? onProgress;

  /// How many times a download is tried when the connection drops or the server
  /// answers 5xx/429, and how long to wait before each new try.
  final int attempts;
  final List<Duration> retryPause;

  EngineInstaller({
    http.Client? client,
    this.manifestUrl = EngineConfig.manifestUrl,
    this.publicKey = EngineConfig.publicKey,
    String? platformKey,
    Directory? installDir,
    this.checkEvery = EngineConfig.checkEvery,
    DateTime Function()? now,
    this.onProgress,
    this.minEngine = EngineConfig.minEngine,
    this.attempts = 3,
    this.retryPause = const [Duration(seconds: 1), Duration(seconds: 3)],
  })  : _client = client ?? http.Client(),
        platformKey = platformKey ?? EngineConfig.platformKey(),
        installDir = installDir ?? EngineConfig.installDir(),
        _now = now ?? DateTime.now;

  /// The oldest installed engine that is kept without looking at the feed.
  final EngineVersion minEngine;

  File get binary => File(p.join(installDir.path, EngineConfig.exeName));
  File get _stamp => File(p.join(installDir.path, '.last_check'));

  /// The engine to run: `SHEPHERD_AI_ENGINE` if set, else the installed one,
  /// installed or updated first when needed. [force] asks the feed now.
  Future<File> ensure({bool force = false}) async {
    final override = Platform.environment[EngineConfig.engineEnv];
    if (override != null && override.isNotEmpty) {
      final f = File(override);
      if (!f.existsSync()) {
        throw EngineInstallException(t('installer.env_missing',
            {'env': EngineConfig.engineEnv, 'path': override}));
      }
      return f;
    }

    final installed =
        binary.existsSync() ? await installedVersion(binary) : null;
    // An engine older than this CLI needs (EngineConfig.minEngine) is updated now,
    // not at the next look at the feed.
    final outdated = installed != null && installed.compareTo(minEngine) < 0;
    if (installed != null && !force && !outdated && _checkedRecently()) {
      return binary;
    }

    final EngineManifest manifest;
    try {
      // Someone who already has an engine does not wait for retries just to look
      // for an update: this run skips the check and the next one asks again.
      manifest =
          await _fetchVerified(attempts: installed == null ? attempts : 1);
    } on EngineInstallException {
      // A broken or untrusted feed never replaces a working engine.
      if (installed != null) return binary;
      rethrow;
    } catch (e) {
      if (installed != null) return binary; // offline: keep using what is here
      throw EngineInstallException(t('installer.download_failed', {'e': e}));
    }
    _markChecked();
    if (installed != null && !(manifest.version > installed)) return binary;

    final package = manifest.packages[platformKey];
    if (package == null) {
      throw EngineInstallException(t('installer.no_package',
          {'platform': platformKey ?? t('installer.unknown_platform')}));
    }
    onProgress?.call(t('installer.downloading', {'version': manifest.version}));
    await _install(package);
    return binary;
  }

  /// `shepherd_ai --version` prints `shepherd_ai 1.2.3 (protocol 2)`.
  Future<EngineVersion?> installedVersion(File exe) async {
    try {
      final r = await Process.run(exe.path, ['--version'])
          .timeout(const Duration(seconds: 10));
      final m = RegExp(r'(\d+\.\d+\.\d+)').firstMatch('${r.stdout}');
      return m == null ? null : EngineVersion.tryParse(m.group(1)!);
    } catch (_) {
      return null;
    }
  }

  bool _checkedRecently() {
    try {
      final at = DateTime.parse(_stamp.readAsStringSync().trim());
      return _now().difference(at) < checkEvery;
    } catch (_) {
      return false;
    }
  }

  void _markChecked() {
    try {
      installDir.createSync(recursive: true);
      _stamp.writeAsStringSync(_now().toUtc().toIso8601String());
    } catch (_) {}
  }

  Future<EngineManifest> _fetchVerified({required int attempts}) async {
    final feed = await _get(manifestUrl, const Duration(seconds: 15), attempts);
    if (feed.statusCode != 200) {
      throw EngineInstallException(
          t('installer.feed_status', {'status': feed.statusCode}));
    }
    final sig =
        await _get('$manifestUrl.sig', const Duration(seconds: 15), attempts);
    if (sig.statusCode != 200 ||
        !EngineSignature.verify(
            message: feed.bodyBytes,
            signatureBase64: sig.body,
            publicKeyBase64: publicKey)) {
      throw EngineInstallException(t('installer.bad_signature'));
    }
    try {
      return EngineManifest.parse(utf8.decode(feed.bodyBytes));
    } on FormatException catch (e) {
      throw EngineInstallException(
          t('installer.bad_feed', {'detail': e.message}));
    }
  }

  Future<void> _install(EnginePackage package) async {
    final List<int> body;
    try {
      body = await _retrying(attempts, () async {
        final res = await _getOnce(package.url, const Duration(minutes: 5));
        if (res.statusCode != 200) {
          throw EngineInstallException(
              t('installer.download_status', {'status': res.statusCode}));
        }
        // A download cut short or damaged on the way is fetched again.
        if (sha256.convert(res.bodyBytes).toString() != package.sha256) {
          throw _Retry(t('installer.bad_hash'));
        }
        return res.bodyBytes;
      });
    } on EngineInstallException {
      rethrow;
    } catch (e) {
      throw EngineInstallException(t('installer.download_failed', {'e': e}));
    }
    final bytes = _extractBinary(package.url, body);
    installDir.createSync(recursive: true);
    // Written beside the target and renamed over it: a failure never leaves half an engine.
    final temp = File('${binary.path}.new');
    temp.writeAsBytesSync(bytes, flush: true);
    if (!Platform.isWindows) Process.runSync('chmod', ['755', temp.path]);
    temp.renameSync(binary.path);
  }

  /// One GET; a 5xx or 429 answer is worth another try.
  Future<http.Response> _getOnce(String url, Duration timeout) async {
    final res = await _client.get(Uri.parse(url)).timeout(timeout);
    if (res.statusCode == 429 || res.statusCode >= 500) {
      throw _Retry(t('installer.server_status', {'status': res.statusCode}));
    }
    return res;
  }

  Future<http.Response> _get(String url, Duration timeout, int attempts) =>
      _retrying(attempts, () => _getOnce(url, timeout));

  /// Runs [op] up to [attempts] times while it fails the way a flaky connection
  /// does (dropped connection, timeout, TLS hiccup, 5xx/429); anything else, such as
  /// a 404 or a bad signature, is final at once. The last error is what comes out.
  Future<T> _retrying<T>(int attempts, Future<T> Function() op) async {
    Object? last;
    for (var i = 0; i < attempts; i++) {
      if (i > 0) {
        onProgress
            ?.call(t('installer.retrying', {'i': i, 'max': attempts - 1}));
        await Future<void>.delayed(
            retryPause[(i - 1).clamp(0, retryPause.length - 1)]);
      }
      try {
        return await op();
      } on _Retry catch (e) {
        last = e;
      } on TimeoutException catch (e) {
        last = e;
      } on SocketException catch (e) {
        last = e;
      } on HandshakeException catch (e) {
        last = e;
      } on http.ClientException catch (e) {
        last = e;
      }
    }
    if (last is _Retry) throw EngineInstallException(last.message);
    throw last!;
  }

  /// The engine binary inside a .tar.gz or .zip package; only that one entry is
  /// read, whatever else the archive holds.
  List<int> _extractBinary(String url, List<int> bytes) {
    final Archive archive = url.endsWith('.zip')
        ? ZipDecoder().decodeBytes(bytes)
        : TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));
    for (final f in archive) {
      if (f.isFile && p.basename(f.name) == EngineConfig.exeName) {
        return f.content as List<int>;
      }
    }
    throw EngineInstallException(
        t('installer.no_binary', {'exe': EngineConfig.exeName}));
  }
}

/// A failure that another try may fix.
class _Retry implements Exception {
  final String message;
  const _Retry(this.message);
}
