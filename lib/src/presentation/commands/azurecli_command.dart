import 'dart:io';

/// Installs Azure CLI using the official installation script for Unix systems.
Future<void> runAzureCliInstallCommand(List<String> args) async {
  print('Installing Azure CLI...');
  if (!Platform.isLinux && !Platform.isMacOS) {
    print(
        '\x1B[31mAzure CLI installation is only supported on Linux and macOS via this command.\x1B[0m');
    return;
  }

  if (Platform.isMacOS) {
    // Check if brew is installed
    final brewCheck = await Process.run('which', ['brew']);
    if ((brewCheck.stdout as String).trim().isEmpty) {
      print('Homebrew not found. Installing Homebrew...');
      final brewInstall = await Process.run(
        'bash',
        [
          '-c',
          'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash'
        ],
        runInShell: true,
      );
      stdout.write(brewInstall.stdout);
      stderr.write(brewInstall.stderr);
      if (brewInstall.exitCode != 0) {
        print('\x1B[31mHomebrew installation failed.\x1B[0m');
        return;
      }
      print('Homebrew installed successfully.');
    }
    print('Installing Azure CLI via Homebrew...');
    final azInstall = await Process.run('brew', ['install', 'azure-cli']);
    stdout.write(azInstall.stdout);
    stderr.write(azInstall.stderr);
    if (azInstall.exitCode == 0) {
      print('\x1B[32mAzure CLI installed successfully.\x1B[0m');
    } else {
      print('\x1B[31mAzure CLI installation failed.\x1B[0m');
    }
    return;
  }

  // Linux (Debian/Ubuntu)
  final installCmd = 'curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash';
  final result = await Process.run('sh', ['-c', installCmd]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode == 0) {
    print('\x1B[32mAzure CLI installed successfully.\x1B[0m');
  } else {
    print('\x1B[31mAzure CLI installation failed.\x1B[0m');
  }
}
