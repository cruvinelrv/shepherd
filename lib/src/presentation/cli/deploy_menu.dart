import 'dart:io';
import 'input_utils.dart';

Future<void> showDeployMenuLoop({
  required Future<void> Function() runChangelogCommand,
}) async {
  const magenta = '\x1B[35m';
  const reset = '\x1B[0m';
  while (true) {
    print('\n$magenta================ DEPLOY MENU =================$reset');
    printDeployMenu();
    final input = stdin.readLineSync();
    print('');
    switch (input?.trim()) {
      case '1':
        await runChangelogCommand();
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

void printDeployMenu() {
  print('''
Shepherd Deploy - Deployment and Release Tools

  1. Update the project CHANGELOG.md
  0. Back to main menu

Select an option (number):
''');
}
