import 'dart:io';
import 'package:shepherd/src/domains/presentation/commands/microfrontends_command.dart';

Future<void> showMicrofrontendsMenu() async {
  while (true) {
    print('\n=== Microfrontends Management ===');
    print('1. List microfrontends');
    print('2. Add microfrontend');
    print('3. Remove microfrontend');
    print('9. Back to Domains menu');
    print('0. Exit');
    stdout.write('Select an option: ');
    final input = stdin.readLineSync();
    switch (input) {
      case '1':
        await runListMicrofrontendsCommand();
        break;
      case '2':
        await runAddMicrofrontendCommand();
        break;
      case '3':
        await runRemoveMicrofrontendCommand();
        break;
      case '9':
        return;
      case '0':
        print('Exiting Shepherd CLI.');
        exit(0);
      default:
        print('Invalid option. Please try again.');
    }
    print('');
    stdout.write('Press Enter to continue...');
    stdin.readLineSync();
  }
}
