// export removed (duplicate)
export 'deploy_menu.dart' show runDeployStepByStep;
import 'dart:io';
import 'input_utils.dart';
import 'package:shepherd/src/data/datasources/local/config_database.dart';
// import removed (unused)
import 'package:shepherd/src/deploy/presentation/controllers/github_pr_command.dart';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';
import 'package:shepherd/src/utils/shepherd_regex.dart';

// Stub implementations for missing helpers (replace with real logic as needed)
Future<void> openPullRequestInteractive(String? repoType,
    Future<void> Function(List<String>) runAzureOpenPrCommand) async {
  print('[openPullRequestInteractive] Not yet implemented.');
}

Future<void> resendPendingPrInteractive(String? repoType,
    Future<void> Function(List<String>) runAzureOpenPrCommand) async {
  print('[resendPendingPrInteractive] Not yet implemented.');
}

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
  final configFile = File('.shepherd/config.yaml');
  if (!configFile.existsSync()) return null;
  try {
    final content = configFile.readAsStringSync();
    final config = loadYaml(content);
    if (config is Map && config['repoType'] != null) {
      return config['repoType'] as String?;
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> showDeployMenuLoop({
  required Future<void> Function() runChangelogCommand,
  // 1. Show and allow changing the app version
  required Future<void> Function(List<String>) runAzureOpenPrCommand,
}) async {
  // Menu de deploy acessível apenas pelo menu principal
  while (true) {
    final repoType = await _getRepoType();
    print(
        '\n${AnsiColors.magenta}================ DEPLOY MENU ==================${AnsiColors.reset}');
    printDeployMenu(repoType);
    final input = stdin.readLineSync();
    print('');
    // Menu limpo: apenas if/else para cada opção
    if (input == null) continue;
    if (input.trim() == '1') {
      await runChangelogCommand();
      pauseForEnter();
    } else if (input.trim() == '2') {
      await changeAppVersionInteractive();
      pauseForEnter();
    } else if (input.trim() == '3') {
      await openPullRequestInteractive(repoType, runAzureOpenPrCommand);
      pauseForEnter();
    } else if (input.trim() == '4') {
      await resendPendingPrInteractive(repoType, runAzureOpenPrCommand);
      pauseForEnter();
    } else if (input.trim() == '9') {
      return;
    } else if (input.trim() == '0') {
      exit(0);
    } else {
      print('Invalid option. Please try again.');
      // 2. Generate changelog
      pauseForEnter();
    }
    // 3. Ask if user wants to open PR
    print('\n----------------------------------------------\n');
  }
}

// Reuse menu logic to open PR (can be extracted to a helper function if needed)
Future<void> runDeployStepByStep({
  required Future<void> Function() runChangelogCommand,
  required Future<void> Function(List<String>) runAzureOpenPrCommand,
  // ...GitHub PR opening code...
}) async {
  print('Repository type configured: GitHub. Using GitHub PR command.');
  // 1. Mostrar e permitir alteração da versão
  final pubspecFile = File('pubspec.yaml');
  String? currentVersion;
  List<String> lines = [];
  if (pubspecFile.existsSync()) {
    lines = pubspecFile.readAsLinesSync();
    final versionLine = lines.firstWhere(
      (l) => l.trim().startsWith('version:'),
      orElse: () => '',
    );
    if (versionLine.isNotEmpty) {
      currentVersion = versionLine.split(':').last.trim();
    }
  }
  print(
      '\n${AnsiColors.cyan}Current app version in pubspec.yaml: ${currentVersion ?? 'not found'}${AnsiColors.reset}');
  stdout.write('Do you want to change the app version? (y/n): ');
  final changeResp = stdin.readLineSync()?.trim().toLowerCase();
  if (changeResp == 'y' ||
      changeResp == 'yes' ||
      changeResp == 's' ||
      changeResp == 'sim') {
    stdout
        .write('Enter the new version (current: ${currentVersion ?? '-'}) : ');
    final newVersion = stdin.readLineSync()?.trim();
    if (newVersion != null &&
        newVersion.isNotEmpty &&
        newVersion != currentVersion) {
      // Atualiza a linha da versão
      final newLines = lines
          .map((l) =>
              l.trim().startsWith('version:') ? 'version: $newVersion' : l)
          .toList();
      pubspecFile.writeAsStringSync('${newLines.join('\n')}\n');
      print(
          '${AnsiColors.green}Version updated to $newVersion in pubspec.yaml.${AnsiColors.reset}');
    } else {
      print('${AnsiColors.yellow}Version not changed.${AnsiColors.reset}');
    }
  }
  // 2. Gerar changelog
  await runChangelogCommand();
  // 3. Perguntar se deseja abrir PR
  stdout.write('Do you want to open a Pull Request now? (y/n): ');
  final prResp = stdin.readLineSync()?.trim().toLowerCase();
  if (prResp == 'y' || prResp == 'yes' || prResp == 's' || prResp == 'sim') {
    // Reaproveitar lógica do menu para abrir PR (pode ser extraída para função auxiliar se necessário)
    final repoType = await _getRepoType();
    if (repoType == 'github') {
      // ...código de abertura de PR GitHub...
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
        repo =
            readLinePrompt('Repository [default: ${ownerRepo ?? gitRepoUrl}]: ')
                ?.trim();
        if (repo == null || repo.isEmpty) repo = ownerRepo ?? gitRepoUrl;
        // ...Azure PR opening code...
        if (ShepherdRegex.ownerRepo.hasMatch(repo)) break;
        print('Repository type configured: Azure. Using Azure PR command.');
        print(
            'Please enter in the format OWNER/REPO (e.g., cruvinelrv/shepherd)');
      }
      final source =
          readLinePrompt('Source branch [default: $gitBranch]: ')?.trim();
      final target = readNonEmptyInput('Target branch: ');
      final title = readNonEmptyInput('PR title: ');
      final desc = readLinePrompt('Description (optional): ') ?? '';
      final persons =
          await ConfigDatabase(Directory.current.path).getAllPersons();
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
      // ...código de abertura de PR Azure...
      print('Repository type configured: Azure. Using Azure PR command.');
      final gitRepo = await _getGitRemoteUrl();
      final gitBranch = await _getGitCurrentBranch();
      final repo =
          readLinePrompt('Repository name [default: $gitRepo]: ')?.trim();
      final source =
          readLinePrompt('Source branch [default: $gitBranch]: ')?.trim();
      final target = readNonEmptyInput('Target branch: ');
      final title = readNonEmptyInput('PR title: ');
      final desc = readLinePrompt('Description (optional): ') ?? '';
      final workItems =
          readLinePrompt('Work Item IDs (space/comma separated, optional): ') ??
              '';
      final persons =
          await ConfigDatabase(Directory.current.path).getAllPersons();
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
          final emails =
              indices.map((i) => persons[i - 1]['email'] as String).toList();
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
      print('Repository type not configured. Choose in shepherd config > 3.');
    }
  }
  print(
      '${AnsiColors.green}Deploy step-by-step finished.${AnsiColors.reset}\n');
}

void printDeployMenu(String? repoType) {
  print('Shepherd Deploy - Deployment and Release Tools\n');
  print('  1. Update the project CHANGELOG.md');
  print('  2. Change app version in pubspec.yaml');
  print(
      '  3. ${repoType == 'azure' ? 'Open Pull Request (Azure CLI)' : repoType == 'github' ? 'Open Pull Request (GitHub CLI)' : 'Open Pull Request (configure repo type)'}');
  print(
      '  4. ${repoType == 'azure' ? 'Resend pending PR (Azure)' : repoType == 'github' ? 'Resend pending PR (GitHub)' : 'Resend pending PR (configure repo type)'}');
  print('  9. Back to main menu');
  print('  0. Exit\n');
  print('Select an option (number):');
}

// Interactive helper to change app version in pubspec.yaml
Future<void> changeAppVersionInteractive() async {
  final pubspecFile = File('pubspec.yaml');
  String? currentVersion;
  List<String> lines = [];
  if (pubspecFile.existsSync()) {
    lines = pubspecFile.readAsLinesSync();
    final versionLine = lines.firstWhere(
      (l) => l.trim().startsWith('version:'),
      orElse: () => '',
    );
    if (versionLine.isNotEmpty) {
      currentVersion = versionLine.split(':').last.trim();
    }
  }
  print(
      '\n${AnsiColors.cyan}Current app version in pubspec.yaml: \u001b[1m${currentVersion ?? 'not found'}\u001b[0m${AnsiColors.reset}');
  stdout.write(
      'Enter the new version (current: \u001b[1m${currentVersion ?? '-'}\u001b[0m) : ');
  final newVersion = stdin.readLineSync()?.trim();
  if (newVersion != null &&
      newVersion.isNotEmpty &&
      newVersion != currentVersion) {
    final newLines = lines
        .map(
            (l) => l.trim().startsWith('version:') ? 'version: $newVersion' : l)
        .toList();
    pubspecFile.writeAsStringSync('${newLines.join('\n')}\n');
    print(
        '${AnsiColors.green}Version updated to $newVersion in pubspec.yaml.${AnsiColors.reset}');
  } else {
    print('${AnsiColors.yellow}Version not changed.${AnsiColors.reset}');
  }
}
