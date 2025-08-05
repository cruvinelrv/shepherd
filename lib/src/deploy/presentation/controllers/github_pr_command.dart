import 'dart:io';
import 'package:shepherd/src/deploy/data/datasources/local/deploy_database.dart';

/// Opens a Pull Request using the GitHub CLI (gh).
/// Requires GitHub CLI to be installed and authenticated.
Future<void> runGithubOpenPrCommand(List<String> args) async {
  print('Opening Pull Request using GitHub CLI...');
  if (args.length < 4) {
    print(
        'Usage: shepherd deploy pr-github <repository> <source-branch> <target-branch> <title> [description] [reviewers]');
    return;
  }
  // Checks if the 'gh' binary is available
  final ghCheck = await Process.run('which', ['gh']);
  if (ghCheck.exitCode != 0) {
    print(
        '\x1B[31mGitHub CLI (gh) não encontrado. Instale pelo menu de ferramentas do Shepherd.\x1B[0m');
    return;
  }

  final repository = args[0];
  final sourceBranch = args[1];
  final targetBranch = args[2];
  final title = args[3];
  final description = args.length > 4 ? args[4] : '';
  final reviewers = args.length > 5 ? args[5] : '';

  // Checks if the user is authenticated in GitHub CLI
  final authCheck = await Process.run('gh', ['auth', 'status']);
  if (authCheck.exitCode != 0) {
    print(
        '\x1B[33mYou are not authenticated in GitHub CLI. The PR will be saved in the database for later submission.\x1B[0m');
    final db = DeployDatabase(Directory.current.path);
    await db.insertPendingPr(
      repository: repository,
      sourceBranch: sourceBranch,
      targetBranch: targetBranch,
      title: title,
      description: description,
      workItems: '',
      reviewers: reviewers,
      createdAt: DateTime.now().toIso8601String(),
    );
    print(
        '\x1B[33mPR saved in the database. You can resend it when authenticated in GitHub CLI.\x1B[0m');
    return;
  }

  // Builds the gh pr create command
  final prArgs = [
    'pr',
    'create',
    '--repo',
    repository,
    '--head',
    sourceBranch,
    '--base',
    targetBranch,
    '--title',
    title,
    '--body',
    description.isNotEmpty ? description : 'Created via Shepherd CLI',
  ];
  if (reviewers.isNotEmpty) {
    prArgs.addAll(['--reviewer', reviewers]);
  }

  final result = await Process.run('gh', prArgs);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode == 0) {
    print('\x1B[32mPull Request successfully created on GitHub!\x1B[0m');
  } else {
    print('\x1B[31mFailed to create Pull Request on GitHub.\x1B[0m');
  }
}
