import 'dart:io';
import 'package:shepherd/src/menu/presentation/cli/owner_utils.dart';
import 'package:shepherd/src/deploy/data/datasources/local/deploy_database.dart';

/// Opens a Pull Request using Azure CLI (az cli).
/// Requires Azure CLI to be installed and user to be logged in.
Future<void> runAzureOpenPrCommand(List<String> args) async {
  print('Opening Pull Request using Azure CLI...');

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
  final description = args.length > 4 ? args[4] : '';
  final workItems = args.length > 5 ? args[5] : '';
  var reviewers = args.length > 6 ? args[6] : '';
  // If reviewers is in the form 'auto:<domain>:<projectPath>', fetch from DB
  if (reviewers.startsWith('auto:')) {
    final parts = reviewers.split(':');
    if (parts.length == 3) {
      final domain = parts[1];
      final projectPath = parts[2];
      final ownerEmails = await fetchOwnerEmailsForDomain(domain, projectPath);
      reviewers = ownerEmails.join(',');
      print('Fetched reviewers from shepherd.db: $reviewers');
    } else {
      print('Invalid auto reviewers format. Use auto:<domain>:<projectPath>');
      reviewers = '';
    }
  }

  if (sourceBranch == targetBranch) {
    print(
        '\x1B[31mSource and target branch cannot be the same. Please select different branches.\x1B[0m');
    return;
  }

  // Only check Azure login when attempting to send
  final loginCheck = await Process.run('az', ['account', 'show']);
  bool azureLoggedIn = loginCheck.exitCode == 0;
  if (azureLoggedIn) {
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
    if (workItems.isNotEmpty) {
      prArgs.addAll(['--work-items', workItems]);
    }
    if (reviewers.isNotEmpty) {
      prArgs.addAll(['--reviewers', reviewers]);
    }

    final result = await Process.run('az', prArgs);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode == 0) {
      print('\x1B[32mPull Request created successfully.\x1B[0m');
    } else {
      print('\x1B[31mFailed to create Pull Request.\x1B[0m');
    }
  } else {
    print(
        '\x1B[33mVocê não está logado no Azure CLI. A PR será salva no banco de dados para envio posterior.\x1B[0m');
    // Save PR to database for later sending
    final db = DeployDatabase(Directory.current.path);
    await db.insertPendingPr(
      repository: repository,
      sourceBranch: sourceBranch,
      targetBranch: targetBranch,
      title: title,
      description: description,
      workItems: workItems,
      reviewers: reviewers,
      createdAt: DateTime.now().toIso8601String(),
    );
    print(
        '\x1B[33mPR salva no banco de dados. Você pode reenviar quando estiver logado no Azure.\x1B[0m');
  }
}
