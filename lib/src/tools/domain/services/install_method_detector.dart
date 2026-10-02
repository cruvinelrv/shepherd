/// How this copy of the Shepherd CLI got onto the machine, which decides how it
/// should be updated.
enum InstallMethod {
  homebrew,
  pubGlobal,
  installScript,

  /// The copy shipped inside Shepherd Studio's app bundle.
  studioBundled,

  /// Running from a checkout with `dart run`.
  source,
  unknown,
}

class InstallMethodDetector {
  /// [executable] is `Platform.resolvedExecutable` (symlinks resolved, so a
  /// Homebrew link shows its Cellar path), [script] is `Platform.script.path`.
  static InstallMethod detect({
    required String executable,
    required String script,
  }) {
    String norm(String p) => p.replaceAll('\\', '/').toLowerCase();
    final exe = norm(executable);
    final scr = norm(script);

    if (exe.contains('.app/contents/') && exe.contains('/shepherd_cli/')) {
      return InstallMethod.studioBundled;
    }

    // Running on the Dart VM: the *script* tells us how it was installed. The
    // VM's own path says nothing (a Dart SDK from Homebrew lives in the Cellar
    // even when the CLI came from pub.dev).
    final exeName = exe.split('/').last;
    if (exeName == 'dart' || exeName == 'dart.exe') {
      // `dart pub global activate` runs the package (or its snapshot) from the pub cache.
      if (scr.contains('/.pub-cache/') || scr.contains('/pub/cache/')) {
        return InstallMethod.pubGlobal;
      }
      return scr.endsWith('.dart')
          ? InstallMethod.source
          : InstallMethod.unknown;
    }

    // A native executable: its own location says where it came from.
    if (exe.contains('/cellar/') ||
        exe.contains('/homebrew/') ||
        exe.contains('/linuxbrew/')) {
      return InstallMethod.homebrew;
    }
    // The install script puts the binary in ~/.shepherd/bin. Matching the folder
    // (not $HOME) keeps this working when HOME itself goes through a symlink.
    if (exe.contains('/.shepherd/bin/')) {
      return InstallMethod.installScript;
    }
    return InstallMethod.unknown;
  }

  static const brewCommand = 'brew update && brew upgrade shepherd_cli';
  static const pubCommand = 'dart pub global activate shepherd';
  static const curlCommand =
      'curl -fsSL https://raw.githubusercontent.com/cruvinelrv/shepherd/main/scripts/install.sh | bash';
  static const powershellCommand =
      'irm https://raw.githubusercontent.com/cruvinelrv/shepherd/main/scripts/install.ps1 | iex';

  /// The command that updates an install of this kind, or null when there is
  /// none to run (Studio bundle, source checkout, unknown).
  static String? updateCommand(InstallMethod method, {bool windows = false}) {
    switch (method) {
      case InstallMethod.homebrew:
        return brewCommand;
      case InstallMethod.pubGlobal:
        return pubCommand;
      case InstallMethod.installScript:
        return windows ? powershellCommand : curlCommand;
      case InstallMethod.studioBundled:
      case InstallMethod.source:
      case InstallMethod.unknown:
        return null;
    }
  }

  static String label(InstallMethod method) => switch (method) {
        InstallMethod.homebrew => 'Homebrew (shepherd_cli)',
        InstallMethod.pubGlobal => 'pub.dev (dart pub global)',
        InstallMethod.installScript =>
          'script de instalação (curl / PowerShell)',
        InstallMethod.studioBundled => 'embutido no Shepherd Studio',
        InstallMethod.source => 'código-fonte (dart run)',
        InstallMethod.unknown => 'não identificado',
      };
}
