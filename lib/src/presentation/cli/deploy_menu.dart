import 'dart:io';
import 'input_utils.dart';
import 'package:shepherd/src/data/datasources/local/shepherd_database.dart';
import 'package:shepherd/src/presentation/commands/github_pr_command.dart';
import 'dart:convert';
import 'package:shepherd/src/utils/ansi_colors.dart';
import 'package:shepherd/src/utils/shepherd_regex.dart';

Future<String> _getGitRemoteUrl() async {
  final result = await Process.run('git', ['remote', 'get-url', 'origin']);
  if (result.exitCode == 0) {
    return (result.stdout as String).trim();
  }
  return '';
}

Future<String> _getGitCurrentBranch() async {
  final result =
      await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  if (result.exitCode == 0) {
    return (result.stdout as String).trim();
  }
  return '';
}

Future<String?> _getRepoType() async {
  final configFile = File('.shepherd/config.json');
  if (!configFile.existsSync()) return null;
  try {
    final config = jsonDecode(configFile.readAsStringSync());
    return config['repoType'] as String?;
  } catch (_) {
    return null;
  }
}

Future<void> showDeployMenuLoop({
  required Future<void> Function() runChangelogCommand,
  required Future<void> Function(List<String>) runAzureOpenPrCommand,
}) async {
  while (true) {
    final repoType = await _getRepoType();
    print(
        '\n${AnsiColors.magenta}================ DEPLOY MENU ==================${AnsiColors.reset}');
    printDeployMenu(repoType);
    final input = stdin.readLineSync();
    print('');
    switch (input?.trim()) {
      case '1':
        await runChangelogCommand();
        pauseForEnter();
        break;
      case '2':
        if (repoType == 'github') {
          // ...existing code for GitHub PR...
          print(
              'Tipo de repositório configurado: GitHub. Usando comando de PR do GitHub.');
          final gitRepoUrl = await _getGitRemoteUrl();
          final gitBranch = await _getGitCurrentBranch();
          String? ownerRepo;
          final match = ShepherdRegex.githubRepo.firstMatch(gitRepoUrl);
          if (match != null && match.groupCount >= 1) {
            ownerRepo = match.group(1);
          }
          String? repo;
          while (true) {
            repo = readLinePrompt(
                    'Repository [default: ${ownerRepo ?? gitRepoUrl}]: ')
                ?.trim();
            if (repo == null || repo.isEmpty) repo = ownerRepo ?? gitRepoUrl;
            if (ShepherdRegex.ownerRepo.hasMatch(repo)) break;
            print(
                'Please enter in the format OWNER/REPO (e.g., cruvinelrv/shepherd)');
          }
          final source =
              readLinePrompt('Source branch [default: $gitBranch]: ')?.trim();
          final target = readNonEmptyInput('Target branch: ');
          final title = readNonEmptyInput('PR title: ');
          final desc = readLinePrompt('Description (optional): ') ?? '';
          final db = ShepherdDatabase(Directory.current.path);
          final persons = await db.getAllPersons();
          String reviewers = '';
          if (persons.isNotEmpty) {
            print(
                '\nSelect code reviewers (comma separated numbers, leave blank for none):');
            for (var i = 0; i < persons.length; i++) {
              final p = persons[i];
              final ghUser = (p['github_username'] ?? '').toString().trim();
              final reviewerLabel =
                  ghUser.isNotEmpty ? '$ghUser <${p['email']}>' : p['email'];
              print(
                  '  \x1B[36m${i + 1}. $reviewerLabel\x1B[0m${p['type'] != null ? ' [${p['type']}]' : ''}');
            }
            final selection = readLinePrompt('Reviewers: ');
            if (selection != null && selection.trim().isNotEmpty) {
              final indices = selection
                  .split(',')
                  .map((s) => int.tryParse(s.trim()) ?? 0)
                  .where((i) => i > 0 && i <= persons.length)
                  .toList();
              final handles = indices.map((i) {
                final p = persons[i - 1];
                final ghUser = (p['github_username'] ?? '').toString().trim();
                return ghUser.isNotEmpty ? ghUser : p['email'];
              }).toList();
              reviewers = handles.join(',');
            }
          }
          await runGithubOpenPrCommand([
            repo,
            (source != null && source.isNotEmpty) ? source : gitBranch,
            target,
            title,
            desc,
            reviewers
          ]);
        } else if (repoType == 'azure') {
          // ...existing code for Azure PR...
          print(
              'Tipo de repositório configurado: Azure. Usando comando de PR do Azure.');
          final gitRepo = await _getGitRemoteUrl();
          final gitBranch = await _getGitCurrentBranch();
          final repo =
              readLinePrompt('Repository name [default: $gitRepo]: ')?.trim();
          final source =
              readLinePrompt('Source branch [default: $gitBranch]: ')?.trim();
          final target = readNonEmptyInput('Target branch: ');
          final title = readNonEmptyInput('PR title: ');
          final desc = readLinePrompt('Description (optional): ') ?? '';
          final workItems = readLinePrompt(
                  'Work Item IDs (space/comma separated, optional): ') ??
              '';
          final db = ShepherdDatabase(Directory.current.path);
          final persons = await db.getAllPersons();
          String reviewers = '';
          if (persons.isNotEmpty) {
            print(
                '\nSelect code reviewers (comma separated numbers, leave blank for none):');
            for (var i = 0; i < persons.length; i++) {
              final p = persons[i];
              final reviewerLabel = p['email'];
              print(
                  '  \x1B[36m${i + 1}. $reviewerLabel\x1B[0m${p['type'] != null ? ' [${p['type']}]' : ''}');
            }
            final selection = readLinePrompt('Reviewers: ');
            if (selection != null && selection.trim().isNotEmpty) {
              final indices = selection
                  .split(',')
                  .map((s) => int.tryParse(s.trim()) ?? 0)
                  .where((i) => i > 0 && i <= persons.length)
                  .toList();
              final emails = indices
                  .map((i) => persons[i - 1]['email'] as String)
                  .toList();
              reviewers = emails.join(',');
            }
          }
          await runAzureOpenPrCommand([
            (repo != null && repo.isNotEmpty) ? repo : gitRepo,
            (source != null && source.isNotEmpty) ? source : gitBranch,
            target,
            title,
            desc,
            workItems,
            reviewers
          ]);
        } else {
          print(
              'Tipo de repositório não configurado. Escolha em shepherd config > 3.');
        }
        pauseForEnter();
        break;
      case '3':
        if (repoType == 'azure') {
          // ...existing code for resend Azure PR...
          final db = ShepherdDatabase(Directory.current.path);
          final pending = await db.getAllPendingPrs();
          if (pending.isEmpty) {
            print('Nenhuma PR pendente encontrada.');
            pauseForEnter();
            break;
          }
          final pr = pending.last;
          print(
              'Reenviando PR: [${pr['repository']}] ${pr['title']} (${pr['source_branch']} -> ${pr['target_branch']})');
          await runAzureOpenPrCommand([
            pr['repository'],
            pr['source_branch'],
            pr['target_branch'],
            pr['title'],
            pr['description'] ?? '',
            pr['work_items'] ?? '',
            pr['reviewers'] ?? '',
          ]);
          await db.deletePendingPr(pr['id'] as int);
          print('Processo concluído. PR pendente removida da lista.');
          pauseForEnter();
        } else if (repoType == 'github') {
          // ...existing code for resend GitHub PR...
          final db = ShepherdDatabase(Directory.current.path);
          final pending = await db.getAllPendingPrs();
          if (pending.isEmpty) {
            print('Nenhuma PR pendente encontrada.');
            pauseForEnter();
            break;
          }
          final pr = pending.last;
          print(
              "Reenviando PR no GitHub: [\x1B[36m${pr['repository']}\x1B[0m] ${pr['title']} (\x1B[36m${pr['source_branch']}\x1B[0m -> \x1B[36m${pr['target_branch']}\x1B[0m)");
          await runGithubOpenPrCommand([
            pr['repository'],
            pr['source_branch'],
            pr['target_branch'],
            pr['title'],
            pr['description'] ?? '',
            pr['reviewers'] ?? '',
          ]);
          await db.deletePendingPr(pr['id'] as int);
          print('Processo concluído. PR pendente removida da lista.');
          pauseForEnter();
        } else {
          print(
              'Tipo de repositório não configurado. Escolha em shepherd config > 3.');
          pauseForEnter();
        }
        break;
      case '0':
        print('Exiting Shepherd CLI.');
        exit(0);
      case '9':
        print('Returning to main menu...');
        return;
      default:
        print('Invalid option. Please try again.');
        pauseForEnter();
    }
    print('\n----------------------------------------------\n');
  }
}

void printDeployMenu(String? repoType) {
  print('Shepherd Deploy - Deployment and Release Tools\n');
  print('  1. Update the project CHANGELOG.md');
  print(
      '  2. ${repoType == 'azure' ? 'Open Pull Request (Azure CLI)' : repoType == 'github' ? 'Open Pull Request (GitHub CLI)' : 'Open Pull Request (configure repo type)'}');
  print(
      '  3. ${repoType == 'azure' ? 'Resend pending PR (Azure)' : repoType == 'github' ? 'Resend pending PR (GitHub)' : 'Resend pending PR (configure repo type)'}');
  print('  9. Back to main menu');
  print('  0. Exit\n');
  print('Select an option (number):');
}
