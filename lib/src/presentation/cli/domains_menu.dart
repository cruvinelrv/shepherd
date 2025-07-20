import 'dart:io';
import 'input_utils.dart';
import 'stories_menu.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';

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
        await runExportYamlCommand();
        pauseForEnter();
        break;
      case '5':
        stdout.write('Enter domain name to delete: ');
        final domain = stdin.readLineSync();
        if (domain != null && domain.isNotEmpty) {
          await runDeleteCommand(domain.trim());
        } else {
          print('Invalid domain name.');
        }
        pauseForEnter();
        break;
      case '6':
        // Passa string vazia para stories_menu, seleção será feita lá
        await showStoriesMenu('');
        pauseForEnter();
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

void printDomainsMenu() {
  print('''
Shepherd Domains - Manage and Analyze Project Domains

  1. Analyze domains
  2. Add owner to a domain
  3. List all domains and owners
  4. Export domains and owners to YAML
  5. Delete a domain
  6. Manage User Stories & Tasks
  9. Back to main menu
  0. Exit

Select an option (number):
''');
}
