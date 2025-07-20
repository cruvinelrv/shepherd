import 'dart:io';
import 'package:shepherd/src/data/shepherd_database.dart';

/// Abre uma Pull Request usando a CLI do GitHub (gh).
/// Requer a CLI do GitHub instalada e autenticada.
Future<void> runGithubOpenPrCommand(List<String> args) async {
  print('Opening Pull Request using GitHub CLI...');
  if (args.length < 4) {
    print(
        'Usage: shepherd deploy pr-github <repository> <source-branch> <target-branch> <title> [description] [reviewers]');
    return;
  }
  // Verifica se o binário 'gh' está disponível
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

  // Checa se está autenticado no GitHub CLI
  final authCheck = await Process.run('gh', ['auth', 'status']);
  if (authCheck.exitCode != 0) {
    print(
        '\x1B[33mVocê não está autenticado no GitHub CLI. A PR será salva no banco de dados para envio posterior.\x1B[0m');
    final db = ShepherdDatabase(Directory.current.path);
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
        '\x1B[33mPR salva no banco de dados. Você pode reenviar quando estiver autenticado no GitHub CLI.\x1B[0m');
    return;
  }

  // Monta o comando gh pr create
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
    print('\x1B[32mPull Request criada com sucesso no GitHub!\x1B[0m');
  } else {
    print('\x1B[31mFalha ao criar Pull Request no GitHub.\x1B[0m');
  }
}
