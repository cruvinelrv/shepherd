import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

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

  EngineInstaller({
    http.Client? client,
    this.manifestUrl = EngineConfig.manifestUrl,
    this.publicKey = EngineConfig.publicKey,
    String? platformKey,
    Directory? installDir,
    this.checkEvery = EngineConfig.checkEvery,
    DateTime Function()? now,
    this.onProgress,
  })  : _client = client ?? http.Client(),
        platformKey = platformKey ?? EngineConfig.platformKey(),
        installDir = installDir ?? EngineConfig.installDir(),
        _now = now ?? DateTime.now;

  File get binary => File(p.join(installDir.path, EngineConfig.exeName));
  File get _stamp => File(p.join(installDir.path, '.last_check'));

  /// The engine to run: `SHEPHERD_AI_ENGINE` if set, else the installed one,
  /// installed or updated first when needed. [force] asks the feed now.
  Future<File> ensure({bool force = false}) async {
    final override = Platform.environment[EngineConfig.engineEnv];
    if (override != null && override.isNotEmpty) {
      final f = File(override);
      if (!f.existsSync()) {
        throw EngineInstallException(
            '${EngineConfig.engineEnv} aponta para um arquivo que não existe: $override');
      }
      return f;
    }

    final installed =
        binary.existsSync() ? await installedVersion(binary) : null;
    if (installed != null && !force && _checkedRecently()) return binary;

    final EngineManifest manifest;
    try {
      manifest = await _fetchVerified();
    } on EngineInstallException {
      // A broken or untrusted feed never replaces a working engine.
      if (installed != null) return binary;
      rethrow;
    } catch (e) {
      if (installed != null) return binary; // offline: keep using what is here
      throw EngineInstallException(
          'Não foi possível baixar o motor de IA ($e). Conecte-se à internet e tente de novo.');
    }
    _markChecked();
    if (installed != null && !(manifest.version > installed)) return binary;

    final package = manifest.packages[platformKey];
    if (package == null) {
      throw EngineInstallException(
          'Ainda não há motor de IA publicado para este computador (${platformKey ?? 'plataforma desconhecida'}).');
    }
    onProgress?.call('Baixando o motor de IA ${manifest.version}...');
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

  Future<EngineManifest> _fetchVerified() async {
    final feed = await _client
        .get(Uri.parse(manifestUrl))
        .timeout(const Duration(seconds: 15));
    if (feed.statusCode != 200) {
      throw EngineInstallException(
          'O servidor de atualizações respondeu ${feed.statusCode}.');
    }
    final sig = await _client
        .get(Uri.parse('$manifestUrl.sig'))
        .timeout(const Duration(seconds: 15));
    if (sig.statusCode != 200 ||
        !EngineSignature.verify(
            message: feed.bodyBytes,
            signatureBase64: sig.body,
            publicKeyBase64: publicKey)) {
      throw const EngineInstallException(
          'A assinatura da lista de versões do motor não confere. Nada foi instalado.');
    }
    try {
      return EngineManifest.parse(utf8.decode(feed.bodyBytes));
    } on FormatException catch (e) {
      throw EngineInstallException('Lista de versões inválida: ${e.message}');
    }
  }

  Future<void> _install(EnginePackage package) async {
    final res = await _client
        .get(Uri.parse(package.url))
        .timeout(const Duration(minutes: 5));
    if (res.statusCode != 200) {
      throw EngineInstallException(
          'Não foi possível baixar o motor (${res.statusCode}).');
    }
    if (sha256.convert(res.bodyBytes).toString() != package.sha256) {
      throw const EngineInstallException(
          'O arquivo baixado não confere com o hash da lista assinada. Nada foi instalado.');
    }
    final bytes = _extractBinary(package.url, res.bodyBytes);
    installDir.createSync(recursive: true);
    // Written beside the target and renamed over it: a failure never leaves half an engine.
    final temp = File('${binary.path}.new');
    temp.writeAsBytesSync(bytes, flush: true);
    if (!Platform.isWindows) Process.runSync('chmod', ['755', temp.path]);
    temp.renameSync(binary.path);
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
        'O pacote do motor não traz ${EngineConfig.exeName}.');
  }
}
