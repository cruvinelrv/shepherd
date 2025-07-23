import 'dart:io';
import 'dart:convert';
import 'package:shepherd/src/utils/ansi_colors.dart';

const _envFilePath = '.shepherd/environments.json';

Future<void> showEnvironmentsMenu() async {
  while (true) {
    final envs = await _readEnvironments();
    print('\n${AnsiColors.magenta}=== Environments Management ===${AnsiColors.reset}');
    print('Current environments:');
    for (var i = 0; i < envs.length; i++) {
      print('  ${i + 1}. ${envs[i]}');
    }
    print('\nOptions:');
    print('  1. Add environment');
    print('  2. Remove environment');
    print('  9. Back to main menu');
    print('  0. Exit');
    stdout.write('Select an option: ');
    final input = stdin.readLineSync()?.trim();
    if (input == '1') {
      stdout.write('Enter new environment name: ');
      final name = stdin.readLineSync()?.trim();
      if (name != null && name.isNotEmpty && !envs.contains(name)) {
        envs.add(name);
        await _writeEnvironments(envs);
        print('${AnsiColors.green}Environment "$name" added.${AnsiColors.reset}');
      } else {
        print('${AnsiColors.yellow}Invalid or duplicate environment.${AnsiColors.reset}');
      }
    } else if (input == '2') {
      stdout.write('Enter the number of the environment to remove: ');
      final idx = int.tryParse(stdin.readLineSync() ?? '');
      if (idx != null && idx > 0 && idx <= envs.length) {
        final removed = envs.removeAt(idx - 1);
        await _writeEnvironments(envs);
        print('${AnsiColors.green}Environment "$removed" removed.${AnsiColors.reset}');
      } else {
        print('${AnsiColors.yellow}Invalid selection.${AnsiColors.reset}');
      }
    } else if (input == '9') {
      return;
    } else if (input == '0') {
      print('Exiting Shepherd CLI.');
      exit(0);
    } else {
      print('Invalid option.');
    }
  }
}

Future<List<String>> _readEnvironments() async {
  final file = File(_envFilePath);
  if (!file.existsSync()) return [];
  try {
    final content = await file.readAsString();
    final list = jsonDecode(content);
    return List<String>.from(list);
  } catch (_) {
    return [];
  }
}

Future<void> _writeEnvironments(List<String> envs) async {
  final file = File(_envFilePath);
  await file.writeAsString(jsonEncode(envs));
}
