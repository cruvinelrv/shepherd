import 'dart:io';

/// Installs GitHub CLI (gh) automatically, detecting the platform.
Future<void> runGithubCliInstallCommand(List<String> args) async {
  print('Installing GitHub CLI (gh)...');
  if (Platform.isMacOS) {
    print('Detected macOS. Installing via Homebrew...');
    final result = await Process.run('brew', ['install', 'gh']);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode == 0) {
      print('\x1B[32mGitHub CLI successfully installed!\x1B[0m');
    } else {
      print('\x1B[31mFailed to install GitHub CLI.\x1B[0m');
    }
  } else if (Platform.isLinux) {
    print('Detected Linux. Installing via apt, dnf or official packages...');
    // Try apt
    final aptCheck = await Process.run('which', ['apt']);
    if (aptCheck.exitCode == 0) {
      final result = await Process.run('sudo', ['apt', 'install', '-y', 'gh']);
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode == 0) {
        print('\x1B[32mGitHub CLI successfully installed!\x1B[0m');
        return;
      }
    }
    // Try dnf
    final dnfCheck = await Process.run('which', ['dnf']);
    if (dnfCheck.exitCode == 0) {
      final result = await Process.run('sudo', ['dnf', 'install', '-y', 'gh']);
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode == 0) {
        print('\x1B[32mGitHub CLI successfully installed!\x1B[0m');
        return;
      }
    }
    print(
        'Please check https://cli.github.com/manual/installation for instructions specific to your distribution.');
  } else if (Platform.isWindows) {
    print('Detected Windows. Installing via winget...');
    final result =
        await Process.run('winget', ['install', '--id', 'GitHub.cli', '-e']);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode == 0) {
      print('\x1B[32mGitHub CLI successfully installed!\x1B[0m');
    } else {
      print('\x1B[31mFailed to install GitHub CLI.\x1B[0m');
      print('Download manually at: https://cli.github.com/manual/installation');
    }
  } else {
    print('Operating system not supported for automatic installation.');
    print('Check https://cli.github.com/manual/installation for instructions.');
  }
}
