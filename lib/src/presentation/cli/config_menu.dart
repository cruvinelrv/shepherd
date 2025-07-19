import 'dart:io';
import 'input_utils.dart';

Future<void> showConfigMenuLoop({
  required Future<void> Function() runConfigCommand,
}) async {
  const yellow = '\x1B[33m';
  const reset = '\x1B[0m';
  while (true) {
    print('\n$yellow================ CONFIG MENU =================$reset');
    printConfigMenu();
    final input = stdin.readLineSync();
    print('');
    switch (input?.trim()) {
      case '1':
        await runConfigCommand();
        pauseForEnter();
        break;
      case '2':
        print('Global CLI settings adjustment not implemented yet.');
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

void printConfigMenu() {
  print('''
Shepherd Config - Configuration and Settings

  1. Interactive configuration for Shepherd
  2. Adjust global CLI settings
  0. Back to main menu

Select an option (number):
''');
}
