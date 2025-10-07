import 'dart:io';
import 'package:shepherd/src/utils/ansi_colors.dart';
import 'package:yaml/yaml.dart';
import '../../../config/data/datasources/local/config_database.dart';
import '../../../deploy/presentation/controllers/github_pr_command.dart';
import '../../../utils/shepherd_regex.dart';
import 'input_utils.dart';
import 'microfrontends_menu.dart';

// Helper to check if Pull Request is enabled
bool isPullRequestEnabled() {
  final configFile = File('.shepherd/config.yaml');
  if (!configFile.existsSync()) return true;
  try {
    final content = configFile.readAsStringSync();
    final config = loadYaml(content);
    if (config is Map && config.containsKey('pullRequestEnabled')) {
      return config['pullRequestEnabled'] == true;
    }
    return true;
  } catch (_) {
    return true;
  }
}

// Automatically updates the version in the root pubspec.yaml, or in the first microfrontend if root does not exist
void setAppVersionAuto(String newVersion) {
  final pubspecFile = File('pubspec.yaml');
  bool updatedRoot = false;
  if (pubspecFile.existsSync()) {
    stdout.write('Do you also want to update the root pubspec.yaml? (y/N): ');
    final resp = stdin.readLineSync()?.trim().toLowerCase();
    if (resp == 'y' || resp == 'yes' || resp == 's' || resp == 'sim') {
      final lines = pubspecFile.readAsLinesSync();
      final newLines =
          lines.map((l) => l.trim().startsWith('version:') ? 'version: $newVersion' : l).toList();
      pubspecFile.writeAsStringSync('${newLines.join('\n')}\n');
      print(
          '${AnsiColors.green}Version updated to $newVersion in pubspec.yaml (root).${AnsiColors.reset}');
      updatedRoot = true;
    } else {
      print('${AnsiColors.yellow}Root pubspec.yaml was not changed.${AnsiColors.reset}');
    }
  }
  // Update all microfrontends
  final microfrontends = loadMicrofrontends();
  bool anyUpdated = false;
  for (final m in microfrontends) {
    final path = m['path']?.toString();
    if (path != null && path.isNotEmpty) {
      final pubspec = File('$path/pubspec.yaml');
      if (pubspec.existsSync()) {
        final mfLines = pubspec.readAsLinesSync();
        final mfNewLines = mfLines
            .map((l) => l.trim().startsWith('version:') ? 'version: $newVersion' : l)
            .toList();
        pubspec.writeAsStringSync('${mfNewLines.join('\n')}\n');
        print(
            '${AnsiColors.green}Version updated to $newVersion in $path/pubspec.yaml.${AnsiColors.reset}');
        anyUpdated = true;
      } else {
        print(
            '${AnsiColors.yellow}No pubspec.yaml found in microfrontend path ($path).${AnsiColors.reset}');
      }
    }
  }
  if (!updatedRoot && !anyUpdated) {
    print(
        '${AnsiColors.yellow}No pubspec.yaml found in the root directory and no microfrontends found.${AnsiColors.reset}');
  }
}

// Utility to get the current version (prioritizes microfrontends)
String? getCurrentAppVersion() {
  final microfrontends = loadMicrofrontends();
  if (microfrontends.isNotEmpty) {
    final path = microfrontends.first['path']?.toString();
    if (path != null && path.isNotEmpty) {
      final pubspec = File('$path/pubspec.yaml');
      if (pubspec.existsSync()) {
        final lines = pubspec.readAsLinesSync();
        final versionLine = lines.firstWhere(
          (l) => l.trim().startsWith('version:'),
          orElse: () => '',
        );
        if (versionLine.isNotEmpty) {
          return versionLine.split(':').last.trim();
        }
      }
    }
  } else {
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final lines = pubspecFile.readAsLinesSync();
      final versionLine = lines.firstWhere(
        (l) => l.trim().startsWith('version:'),
        orElse: () => '',
      );
      if (versionLine.isNotEmpty) {
        return versionLine.split(':').last.trim();
      }
    }
  }
  return null;
}

Future<void> openPullRequestInteractive(
    String? repoType, Future<void> Function(List<String>) runAzureOpenPrCommand) async {
  print('[openPullRequestInteractive] Not yet implemented.');
}

Future<void> resendPendingPrInteractive(
    String? repoType, Future<void> Function(List<String>) runAzureOpenPrCommand) async {
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
  final result = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
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
      // You can use config['repoType'] here if needed
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
  // Deploy menu accessible only from the main menu
  while (true) {
    final repoType = await _getRepoType();
    // Always show the current version (prioritizes microfrontends)
    final currentVersion = getCurrentAppVersion();
    print(
        '\n${AnsiColors.cyan}Current app version: \u001b[1m${currentVersion ?? 'not found'}${AnsiColors.reset}');
    print(
        '${AnsiColors.magenta}================ DEPLOY MENU ==================${AnsiColors.reset}');
    printDeployMenu(repoType, pullRequestEnabled: isPullRequestEnabled());
    final input = stdin.readLineSync();
    if (input == null) continue;
    if (input.trim() == '1') {
      await runChangelogCommand();
      pauseForEnter();
    } else if (input.trim() == '2') {
      await changeAppVersionAllMicrofrontendsInteractive();
      pauseForEnter();
    } else if (input.trim() == '3' && isPullRequestEnabled()) {
      await openPullRequestInteractive(repoType, runAzureOpenPrCommand);
      pauseForEnter();
    } else if (input.trim() == '4' && isPullRequestEnabled()) {
      await resendPendingPrInteractive(repoType, runAzureOpenPrCommand);
      pauseForEnter();
    } else if (input.trim() == '9') {
      return;
    } else if (input.trim() == '0') {
      exit(0);
    } else {
      print('Invalid option. Please try again.');
      pauseForEnter();
    }
    print('\n----------------------------------------------\n');
  }
}

// Reuses menu logic to open PR (can be extracted to a helper function if needed)
Future<void> runDeployStepByStep({
  required Future<void> Function(String baseBranch) runChangelogCommand,
  required Future<void> Function(List<String>) runAzureOpenPrCommand,
  // ...GitHub PR opening code...
}) async {
  // 1. Show and allow changing the app version (always asks for user input)
  final currentVersion = getCurrentAppVersion();
  print(
      '\n${AnsiColors.cyan}Current app version: ${currentVersion ?? 'not found'}${AnsiColors.reset}');
  stdout.write('Enter the new version: ');
  final newVersion = stdin.readLineSync()?.trim();
  if (newVersion != null && newVersion.isNotEmpty && newVersion != currentVersion) {
    setAppVersionAuto(newVersion);
    print(
        '${AnsiColors.green}Version updated to $newVersion in microfrontends.${AnsiColors.reset}');
  } else {
    print('${AnsiColors.yellow}Version not changed.${AnsiColors.reset}');
  }
  // Request base branch only once
  stdout.write('Enter the base branch for the changelog (e.g., main, develop): ');
  var baseBranch = stdin.readLineSync();
  if (baseBranch == null || baseBranch.trim().isEmpty) {
    print('Base branch not provided.');
    return;
  }
  baseBranch = baseBranch.trim();
  // 2. Generate changelog
  await runChangelogCommand(baseBranch);
  // 3. Ask if user wants to open PR only if enabled
  if (isPullRequestEnabled()) {
    stdout.write('Do you want to open a Pull Request now? (y/n): ');
    final prResp = stdin.readLineSync()?.trim().toLowerCase();
    if (prResp == 'y' || prResp == 'yes' || prResp == 's' || prResp == 'sim') {
      // ...código de abertura de PR...
      final repoType = await _getRepoType();
      if (repoType == 'github') {
        print('Repository type configured: GitHub. Using GitHub PR command.');
        final gitRepoUrl = await _getGitRemoteUrl();
        final gitBranch = await _getGitCurrentBranch();
        String? ownerRepo;
        final match = ShepherdRegex.githubRepo.firstMatch(gitRepoUrl);
        if (match != null && match.groupCount >= 1) {
          ownerRepo = match.group(1);
        }
        String? repo;
        while (true) {
          repo = readLinePrompt('Repository [default: ${ownerRepo ?? gitRepoUrl}]: ')?.trim();
          if (repo == null || repo.isEmpty) repo = ownerRepo ?? gitRepoUrl;
          if (ShepherdRegex.ownerRepo.hasMatch(repo)) break;
          print('Repository type configured: Azure. Using Azure PR command.');
          print('Please enter in the format OWNER/REPO (e.g., cruvinelrv/shepherd)');
        }
        final source = readLinePrompt('Source branch [default: $gitBranch]: ')?.trim();
        final target = readNonEmptyInput('Target branch: ');
        final title = readNonEmptyInput('PR title: ');
        final desc = readLinePrompt('Description (optional): ') ?? '';
        final persons = await ConfigDatabase(Directory.current.path).getAllPersons();
        String reviewers = '';
        if (persons.isNotEmpty) {
          print('\nSelect code reviewers (comma separated numbers, leave blank for none):');
          for (var i = 0; i < persons.length; i++) {
            final p = persons[i];
            final ghUser = (p['github_username'] ?? '').toString().trim();
            final reviewerLabel = ghUser.isNotEmpty ? '$ghUser <${p['email']}>' : p['email'];
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
        print('Repository type configured: Azure. Using Azure PR command.');
        final gitRepo = await _getGitRemoteUrl();
        final gitBranch = await _getGitCurrentBranch();
        final repo = readLinePrompt('Repository name [default: $gitRepo]: ')?.trim();
        final source = readLinePrompt('Source branch [default: $gitBranch]: ')?.trim();
        final target = readNonEmptyInput('Target branch: ');
        final title = readNonEmptyInput('PR title: ');
        final desc = readLinePrompt('Description (optional): ') ?? '';
        final workItems = readLinePrompt('Work Item IDs (space/comma separated, optional): ') ?? '';
        final persons = await ConfigDatabase(Directory.current.path).getAllPersons();
        String reviewers = '';
        if (persons.isNotEmpty) {
          print('\nSelect code reviewers (comma separated numbers, leave blank for none):');
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
            final emails = indices.map((i) => persons[i - 1]['email'] as String).toList();
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
  }
  print('${AnsiColors.green}Deploy step-by-step finished.${AnsiColors.reset}\n');
}

void printDeployMenu(String? repoType, {bool pullRequestEnabled = true}) {
  print('Shepherd Deploy - Deployment and Release Tools\n');
  print('  1. Update the project CHANGELOG.md');
  print('  2. Change app version in pubspec.yaml');
  if (pullRequestEnabled) {
    print(
        '  3. ${repoType == 'azure' ? 'Open Pull Request (Azure CLI)' : repoType == 'github' ? 'Open Pull Request (GitHub CLI)' : 'Open Pull Request (configure repo type)'}');
    print(
        '  4. ${repoType == 'azure' ? 'Resend pending PR (Azure)' : repoType == 'github' ? 'Resend pending PR (GitHub)' : 'Resend pending PR (configure repo type)'}');
  }
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
  stdout.write('Enter the new version (current: \u001b[1m${currentVersion ?? '-'}\u001b[0m) : ');
  final newVersion = stdin.readLineSync()?.trim();
  if (newVersion != null && newVersion.isNotEmpty && newVersion != currentVersion) {
    final newLines =
        lines.map((l) => l.trim().startsWith('version:') ? 'version: $newVersion' : l).toList();
    pubspecFile.writeAsStringSync('${newLines.join('\n')}\n');
    print('${AnsiColors.green}Version updated to $newVersion in pubspec.yaml.${AnsiColors.reset}');
  } else {
    print('${AnsiColors.yellow}Version not changed.${AnsiColors.reset}');
  }
}

// Updates the version in the root pubspec.yaml and in all microfrontends
Future<void> changeAppVersionAllMicrofrontendsInteractive() async {
  final microfrontends = loadMicrofrontends();
  String? currentVersion;
  File? pubspecFile;
  List<String> lines = [];
  if (microfrontends.isNotEmpty) {
    // Gets the version from one of the microfrontends
    final path = microfrontends.first['path']?.toString();
    if (path != null && path.isNotEmpty) {
      final pubspec = File('$path/pubspec.yaml');
      if (pubspec.existsSync()) {
        lines = pubspec.readAsLinesSync();
        final versionLine = lines.firstWhere(
          (l) => l.trim().startsWith('version:'),
          orElse: () => '',
        );
        if (versionLine.isNotEmpty) {
          currentVersion = versionLine.split(':').last.trim();
        }
      }
    }
    print(
        '\n${AnsiColors.cyan}Current app version in microfrontends: \u001b[1m${currentVersion ?? 'not found'}${AnsiColors.reset}');
  } else {
    // No microfrontends: gets version from root pubspec.yaml
    pubspecFile = File('pubspec.yaml');
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
        '\n${AnsiColors.cyan}Current app version in pubspec.yaml: \u001b[1m${currentVersion ?? 'not found'}${AnsiColors.reset}');
  }
  stdout.write('Enter the new version (current: \u001b[1m${currentVersion ?? '-'}\u001b[0m) : ');
  final newVersion = stdin.readLineSync()?.trim();
  if (newVersion == null || newVersion.isEmpty || newVersion == currentVersion) {
    print('${AnsiColors.yellow}Version not changed.${AnsiColors.reset}');
    return;
  }
  if (microfrontends.isNotEmpty) {
    // Updates all microfrontends and NEVER the root pubspec.yaml
    final updated = <String>[];
    for (final m in microfrontends) {
      final path = m['path']?.toString();
      if (path == null || path.isEmpty) continue;
      final pubspec = File('$path/pubspec.yaml');
      if (!pubspec.existsSync()) {
        print('${AnsiColors.yellow}No pubspec.yaml found in $path.${AnsiColors.reset}');
        continue;
      }
      final mfLines = pubspec.readAsLinesSync();
      final mfNewLines =
          mfLines.map((l) => l.trim().startsWith('version:') ? 'version: $newVersion' : l).toList();
      pubspec.writeAsStringSync('${mfNewLines.join('\n')}\n');
      print(
          '${AnsiColors.green}Version updated to $newVersion in $path/pubspec.yaml.${AnsiColors.reset}');
      updated.add('$path/pubspec.yaml');
    }
    if (updated.isNotEmpty) {
      print(
          '${AnsiColors.cyan}Version updated in ${updated.length} microfrontend(s):${AnsiColors.reset}');
      for (final f in updated) {
        print('  - $f');
      }
    }
    // Never changes the root pubspec.yaml if there are microfrontends
    return;
  }
  // Only updates the root pubspec.yaml if there are NO microfrontends
  if (pubspecFile != null && pubspecFile.existsSync()) {
    final newLines =
        lines.map((l) => l.trim().startsWith('version:') ? 'version: $newVersion' : l).toList();
    pubspecFile.writeAsStringSync('${newLines.join('\n')}\n');
    print('${AnsiColors.green}Version updated to $newVersion in pubspec.yaml.${AnsiColors.reset}');
    print('${AnsiColors.cyan}Version updated only in the root pubspec.yaml.${AnsiColors.reset}');
  }
}
