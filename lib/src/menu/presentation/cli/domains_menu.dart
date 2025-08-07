import 'squads_menu.dart';
import 'dart:io';
import 'input_utils.dart';
import 'stories_menu.dart';
import 'feature_toggle_menu.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';
import 'microfrontends_menu.dart';

typedef DomainMenuActions = Future<void> Function({
  required Future<void> Function() runAnalyzeCommand,
  required Future<void> Function(String) runAddOwnerCommand,
  required Future<void> Function() runListCommand,
  required Future<void> Function() runExportYamlCommand,
  required Future<void> Function(String) runDeleteCommand,
});

Future<void> showDomainsMenuLoop({
  required Future<void> Function() runAnalyzeCommand,
  required Future<void> Function(String) runAddOwnerCommand,
  required Future<void> Function() runListCommand,
  required Future<void> Function() runExportYamlCommand,
  required Future<void> Function(String) runDeleteCommand,
}) async {
  while (true) {
    print(
        '\n${AnsiColors.cyan}================ DOMAINS MENU ==================${AnsiColors.reset}');
    printDomainsMenu();
    final input = stdin.readLineSync();
    print('');
    switch (input?.trim()) {
      case '1':
        await runAnalyzeCommand();
        pauseForEnter();
        break;
      case '2':
        stdout.write('Enter domain name to add owner: ');
        final domain = stdin.readLineSync();
        if (domain != null && domain.isNotEmpty) {
          await runAddOwnerCommand(domain.trim());
        } else {
          print('Invalid domain name.');
        }
        pauseForEnter();
        break;
      case '3':
        await runListCommand();
        pauseForEnter();
        break;
      case '4':
        stdout.write('Enter domain name to delete: ');
        final domain = stdin.readLineSync();
        if (domain != null && domain.isNotEmpty) {
          await runDeleteCommand(domain.trim());
        } else {
          print('Invalid domain name.');
        }
        pauseForEnter();
        break;
      case '5':
        await showStoriesMenu('');
        pauseForEnter();
        break;
      case '6':
        await showFeatureToggleMenu();
        pauseForEnter();
        break;
      case '7':
        await showMicrofrontendsMenu();
        pauseForEnter();
        break;
      case '8':
        await showSquadsMenu();
        pauseForEnter();
        break;
      case '9':
        print('Returning to main menu...');
        return;
      case '0':
        print('Exiting Shepherd CLI.');
        exit(0);
      default:
        print('Invalid option. Please try again.');
        pauseForEnter();
    }
    print('\n----------------------------------------------\n');
  }
}

void printDomainsMenu() {
  print('''
Shepherd Domains - Manage and Analyze Project Domains

  1. Analyze domains
  2. Add owner to a domain
  3. List all domains and owners
  4. Delete a domain
  5. Stories menu
  6. Feature toggles menu
  7. Microfrontends menu
  8. Squads management
  9. Return to main menu
  0. Exit Shepherd CLI
''');
}
