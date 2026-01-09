import 'dart:io';

Future<String> promptInitMode() async {
  print('\nSelect the initialization mode:');
  print('[1] Automation Only (Clean, Changelog, Deploy)');
  print('[2] Full Setup (Automation + DDD/Project Management)');

  while (true) {
    stdout.write('\nChoose an option [1-2] (default: 2): ');
    final input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty || input == '2') {
      return 'full';
    } else if (input == '1') {
      return 'automation';
    } else {
      print('Invalid option. Please enter 1 or 2.');
    }
  }
}
