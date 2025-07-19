import 'dart:io';

/// Opens a Pull Request using Azure CLI (az cli).
/// Requires Azure CLI to be installed and user to be logged in.
Future<void> runAzureOpenPrCommand(List<String> args) async {
  print('Opening Pull Request using Azure CLI...');
  // Check if user is logged in to Azure CLI
  final loginCheck = await Process.run('az', ['account', 'show']);
  if (loginCheck.exitCode != 0) {
    print(
        '\x1B[31mYou are not logged in to Azure CLI. Please run `az login` before creating a Pull Request.\x1B[0m');
    return;
  }

  // Example usage: az repos pr create --repository <repo> --source-branch <branch> --target-branch <target> --title <title> --description <desc>
  if (args.length < 4) {
    print(
        'Usage: shepherd deploy pr <repository> <source-branch> <target-branch> <title> [description]');
    return;
  }
  final repository = args[0];
  final sourceBranch = args[1];
  final targetBranch = args[2];
  final title = args[3];
  final description = args.length > 4 ? args.sublist(4).join(' ') : '';

  final prArgs = [
    'repos',
    'pr',
    'create',
    '--repository',
    repository,
    '--source-branch',
    sourceBranch,
    '--target-branch',
    targetBranch,
    '--title',
    title,
  ];
  if (description.isNotEmpty) {
    prArgs.addAll(['--description', description]);
  }

  final result = await Process.run('az', prArgs);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode == 0) {
    print('\x1B[32mPull Request created successfully.\x1B[0m');
  } else {
    print('\x1B[31mFailed to create Pull Request.\x1B[0m');
  }
}
