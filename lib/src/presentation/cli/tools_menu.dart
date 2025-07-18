import 'dart:io';
import 'input_utils.dart';

Future<void> showToolsMenuLoop({
  required Future<void> Function(List<String>) runCleanCommand,
  required Future<void> Function(List<String>) runLinterCommand,
  required Future<void> Function(List<String>) runFormatCommand,
  required Future<void> Function(List<String>) runAzureCliInstallCommand,
}) async {
  const green = '\x1B[32m';
  const reset = '\x1B[0m';
  while (true) {
    print('\n$green================ TOOLS MENU ==================$reset');
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
        await runLinterCommand([]);
        pauseForEnter();
        break;
      case '4':
        await runFormatCommand([]);
        pauseForEnter();
        break;
      case '0':
        print('\nReturning to main menu...\n');
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
  3. Run linter on the project
  4. Format the code
  0. Back to main menu

Select an option (number):
''');
}
