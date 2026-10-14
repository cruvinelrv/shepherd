import 'dart:io';

import 'engine_manifest.dart';

import 'package:path/path.dart' as p;

/// Where the Shepherd AI engine comes from and whom the CLI trusts to publish it.
///
/// The engine is a separate program (the AI lives there, not in this CLI). It is
/// downloaded on first use from a feed signed by Shepherd, and updated the same way.
class EngineConfig {
  EngineConfig._();

  /// The feed: the newest engine version and one package per platform, each with
  /// its SHA-256. Its signature is the same address plus `.sig`.
  static const manifestUrl =
      'https://www.shepherdplatform.com/releases/ai/latest.json';

  /// The Ed25519 public key (base64) the feed must be signed with.
  static const publicKey = 'rwZhU9yrOv5ldH6/Ma8PEydcheH/ZwP2ZwzU66pBpQ4=';

  /// Environment variable that points to an engine binary to use as it is
  /// (development): nothing is downloaded or checked.
  static const engineEnv = 'SHEPHERD_AI_ENGINE';

  /// The oldest engine this CLI works with (0.3.2 proposes terminal commands, which
  /// `/run` needs). An older one is replaced at once, whatever the last look at the
  /// feed was.
  static const minEngine = EngineVersion(0, 3, 2);

  /// How long a successful look at the feed is trusted before asking again.
  static const checkEvery = Duration(hours: 6);

  /// The feed's name for this computer, or null if no engine is published for it.
  static String? platformKey() {
    if (Platform.isWindows) return 'windows-x64';
    final arch = Process.runSync('uname', ['-m']).stdout.toString().trim();
    if (Platform.isMacOS) {
      return arch == 'arm64' ? 'macos-arm64' : 'macos-x64';
    }
    if (Platform.isLinux && (arch == 'x86_64' || arch == 'amd64')) {
      return 'linux-x64';
    }
    return null;
  }

  static String get exeName =>
      Platform.isWindows ? 'shepherd_ai.exe' : 'shepherd_ai';

  /// `~/.shepherd/bin`.
  static Directory installDir() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return Directory(p.join(home, '.shepherd', 'bin'));
  }
}
