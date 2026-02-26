import 'dart:io';
import '../../domain/services/changelog_service.dart';
import '../../domain/services/update_checker_service.dart';
import '../../../menu/presentation/cli/direct_commands.dart';
import '../../../menu/presentation/cli/general_menu.dart';
import '../../../utils/cli_parser.dart';
import '../commands/clean_command.dart';
import '../commands/deploy_command.dart';
import '../commands/init_command.dart';
import '../commands/git_recover_command.dart';
import '../commands/auto_update_command.dart';
import '../commands/test_command.dart';
import '../../../sync/presentation/commands/pull_command.dart';
import 'package:shepherd/src/version.dart';
import 'package:yaml/yaml.dart';

/// Main Shepherd CLI runner
Future<void> runShepherd(List<String> arguments) async {
  // Check for updates (non-blocking, silent fail)
  await _checkForUpdates();

  if (arguments.isEmpty) {
    // No arguments, show main menu
    await showGeneralMenuLoop();
    return;
  }

  final parser = buildShepherdArgParser();

  try {
    final results = parser.parse(arguments);
    final command = results.command?.name;

    switch (command) {
      case 'changelog':
        await _handleChangelogCommand();
        break;
      case 'clean':
        await runCleanCommand(arguments.skip(1).toList());
        break;
      case 'deploy':
        await runDeployCommand(arguments.skip(1).toList());
        break;
      case 'init':
        await runInitCommand(arguments.skip(1).toList());
        break;
      case 'gitrecover':
        await runGitRecoverStepByStep();
        break;
      case 'auto-update':
        await runAutoUpdateCommand(arguments.skip(1).toList());
        break;
      case 'pull':
        await runPullCommand(arguments.skip(1).toList());
        break;
      case 'test':
        await _handleTestCommand(arguments.skip(1).toList());
        break;
      case 'version':
        print('Shepherd version: \u001b[32m$shepherdVersion\u001b[0m');
        break;
      case 'help':
        _printAppropriateHelp();
        break;
      case 'about':
        DirectCommandsMenu.printShepherdAbout();
        break;
      default:
        if (arguments.isNotEmpty) {
          print('Unknown command: ${arguments.first}');
          print('');
        }
        _printAppropriateHelp();
    }
  } catch (e) {
    print('Error parsing arguments: $e');
    _printAppropriateHelp();
  }
}

/// Handle test command
Future<void> _handleTestCommand(List<String> arguments) async {
  await runTestCommand(arguments);
}

/// Handle changelog command
Future<void> _handleChangelogCommand() async {
  try {
    final service = ChangelogService();
    final cli = service.cli;

    // Prompt for base branch
    final baseBranch = await cli.promptBaseBranch();

    // Prompt for changelog type (update or change)
    final changelogType = await cli.promptChangelogType();

    final updatedPaths = await service.updateChangelog(
      baseBranch: baseBranch,
      changelogType: changelogType,
    );

    if (updatedPaths.isNotEmpty) {
      print('CHANGELOG.md successfully updated for:');
      for (final path in updatedPaths) {
        print('  - $path');
      }
    } else {
      print('No changes detected.');
    }
  } catch (e) {
    print('Error updating changelog: $e');
    exit(1);
  }
}

/// Step-by-step interface for gitrecover
Future<void> runGitRecoverStepByStep() async {
  print('\nShepherd GitRecover - Changelog Recovery by Date');
  String? baseBranch;
  String? sinceStr;
  String? untilStr;
  DateTime? since;
  DateTime? until;
  final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  while (baseBranch == null || baseBranch.trim().isEmpty) {
    stdout.write('Enter the reference branch (e.g., main, develop): ');
    baseBranch = stdin.readLineSync()?.trim();
    if (baseBranch == null || baseBranch.isEmpty) {
      print('Reference branch is required.');
    }
  }
  while (since == null) {
    stdout.write('Enter the start date (YYYY-MM-DD): ');
    sinceStr = stdin.readLineSync()?.trim();
    if (sinceStr != null && dateRegex.hasMatch(sinceStr)) {
      try {
        since = DateTime.parse(sinceStr);
      } catch (_) {
        print('Invalid date. Please try again.');
      }
    } else {
      print('Invalid format. Example: 2025-11-01');
    }
  }
  while (until == null) {
    stdout.write('Enter the end date (YYYY-MM-DD) [optional]: ');
    untilStr = stdin.readLineSync()?.trim();
    if (untilStr == null || untilStr.isEmpty) {
      break;
    }
    if (dateRegex.hasMatch(untilStr)) {
      try {
        until = DateTime.parse(untilStr);
      } catch (_) {
        print('Invalid date. Please try again.');
      }
    } else {
      print('Invalid format. Example: 2025-11-12');
    }
  }
  print('\nSummary:');
  print('  Reference branch: $baseBranch');
  print('  Start date: $sinceStr');
  print('  End date: ${untilStr ?? '-'}');

  // Fetch commits for summary
  final args = [
    'log',
    baseBranch,
    '--pretty=format:%H|%an|%aI|%s',
    '--no-merges',
    '--since=$sinceStr',
  ];
  if (untilStr != null && untilStr.isNotEmpty) {
    args.add('--until=$untilStr');
  }
  final result = await Process.run('git', args, workingDirectory: Directory.current.path);
  final lines =
      (result.stdout as String).split('\n').where((line) => line.trim().isNotEmpty).toList();
  if (lines.isEmpty) {
    print('\nNo commits found for the specified date range.');
  } else {
    print('\nCommits found:');
    for (final line in lines) {
      final parts = line.split('|');
      if (parts.length >= 4) {
        print(
            '  - ${parts[0].substring(0, 7)} | ${parts[2].substring(0, 10)} | ${parts[1]} | ${parts[3]}');
      } else {
        print('  - $line');
      }
    }
  }
  stdout.write('\nDo you want to continue and generate the changelog? (y/n): ');
  final confirm = stdin.readLineSync()?.trim().toLowerCase();
  if (confirm != 's' && confirm != 'sim' && confirm != 'y' && confirm != 'yes') {
    print('Operation cancelled.');
    return;
  }
  await runGitRecoverCommand(
    projectDir: Directory.current.path,
    since: since,
    until: until,
    baseBranch: baseBranch,
  );
}

/// Print help based on project's init mode
void _printAppropriateHelp() {
  final projectFile = File('.shepherd/project.yaml');
  if (projectFile.existsSync()) {
    try {
      final content = projectFile.readAsStringSync();
      final yaml = loadYaml(content);
      if (yaml is Map && yaml['init_mode'] == 'automation') {
        DirectCommandsMenu.printAutomationHelp();
        return;
      }
    } catch (e) {
      // If can't read mode, show full help
    }
  }
  DirectCommandsMenu.printShepherdHelp();
}

/// Check for package updates and display notification if available
Future<void> _checkForUpdates() async {
  try {
    final service = UpdateCheckerService();
    final result = await service.checkAndHandle();

    // Only show notification if in notify mode and update is available
    // (prompt mode is handled internally by the service)
    if (result.updateAvailable) {
      final notification = service.formatUpdateNotification(result);
      if (notification.isNotEmpty) {
        print(notification);
        print(''); // Empty line for spacing
      }
    }
  } catch (e) {
    // Silent fail - update check should never break the CLI
  }
}
