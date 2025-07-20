import 'dart:io';
import 'input_utils.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';

Future<void> showToolsMenuLoop({
  required Future<void> Function(List<String>) runCleanCommand,
  required Future<void> Function(List<String>) runLinterCommand,
  required Future<void> Function(List<String>) runFormatCommand,
  required Future<void> Function(List<String>) runAzureCliInstallCommand,
  required Future<void> Function(List<String>) runGithubCliInstallCommand,
}) async {
  while (true) {
    print('\n${AnsiColors.green}================ TOOLS MENU ==================${AnsiColors.reset}');
    printToolsMenu();
    final input = stdin.readLineSync();
    print('');
    switch (input?.trim()) {
      case '1':
        await runCleanCommand([]);
        pauseForEnter();
        break;
      case '2':
        await runAzureCliInstallCommand([]);
        pauseForEnter();
        break;
      case '3':
        await runGithubCliInstallCommand([]);
        pauseForEnter();
        break;
      case '4':
        await runLinterCommand([]);
        pauseForEnter();
        break;
      case '5':
        await runFormatCommand([]);
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

void printToolsMenu() {
  print('''
Shepherd Tools - Project Maintenance Utilities

  1. Clean all projects (or only the current one)
  2. Install Azure CLI automatically
  3. Install GitHub CLI automatically
  4. Run linter on the project
  5. Format the code
  9. Back to main menu
  0. Exit

Select an option (number):
''');
}
