import 'dart:io';
import '../../domain/services/changelog_service.dart';
import '../../../menu/presentation/cli/direct_commands.dart';
import '../../../utils/cli_parser.dart';

/// Main Shepherd CLI runner
Future<void> runShepherd(List<String> arguments) async {
  if (arguments.isEmpty) {
    // No arguments, show help
    DirectCommandsMenu.printShepherdHelp();
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
      case 'help':
        DirectCommandsMenu.printShepherdHelp();
        break;
      case 'about':
        DirectCommandsMenu.printShepherdAbout();
        break;
      default:
        if (arguments.isNotEmpty) {
          print('Unknown command: ${arguments.first}');
          print('');
        }
        DirectCommandsMenu.printShepherdHelp();
    }
  } catch (e) {
    print('Error parsing arguments: $e');
    DirectCommandsMenu.printShepherdHelp();
  }
}

/// Handle changelog command
Future<void> _handleChangelogCommand() async {
  try {
    stdout.write(
        'Enter the base branch for the changelog (e.g., main, develop): ');
    final baseBranch = stdin.readLineSync()?.trim();

    if (baseBranch == null || baseBranch.isEmpty) {
      print('Base branch not provided.');
      return;
    }

    final service = ChangelogService();
    final updatedPaths = await service.updateChangelog(baseBranch: baseBranch);

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
