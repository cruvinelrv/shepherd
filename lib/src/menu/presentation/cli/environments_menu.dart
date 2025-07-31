import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';

const _envFilePath = 'dev_tools/shepherd/environments.yaml';

Future<void> showEnvironmentsMenu() async {
  while (true) {
    final envs = await _readEnvironments();
    print('\n${AnsiColors.magenta}=== Environments Management ===${AnsiColors.reset}');
    print('Environments and their branches:');
    if (envs.isEmpty) {
      print('  (no environments registered)');
    } else {
      int idx = 1;
      envs.forEach((env, branch) {
        print('  $idx. $env: $branch');
        idx++;
      });
    }
    print('\nOptions:');
    print('  1. Add environment');
    print('  2. Remove environment');
    print('  3. Edit environment branch');
    print('  9. Back to main menu');
    print('  0. Exit');
    stdout.write('Select an option: ');
    final input = stdin.readLineSync()?.trim();
    if (input == '1') {
      stdout.write('New environment name: ');
      final name = stdin.readLineSync()?.trim();
      if (name != null && name.isNotEmpty && !envs.containsKey(name)) {
        stdout.write('Associated branch: ');
        final branch = stdin.readLineSync()?.trim();
        if (branch != null && branch.isNotEmpty) {
          envs[name] = branch;
          await _writeEnvironments(envs);
          print('${AnsiColors.green}Environment "$name" added.${AnsiColors.reset}');
        } else {
          print('${AnsiColors.yellow}Invalid branch.${AnsiColors.reset}');
        }
      } else {
        print('${AnsiColors.yellow}Invalid name or environment already exists.${AnsiColors.reset}');
      }
    } else if (input == '2') {
      stdout.write('Environment number to remove: ');
      final idx = int.tryParse(stdin.readLineSync() ?? '');
      if (idx != null && idx > 0 && idx <= envs.length) {
        final key = envs.keys.elementAt(idx - 1);
        envs.remove(key);
        await _writeEnvironments(envs);
        print('${AnsiColors.green}Environment "$key" removed.${AnsiColors.reset}');
      } else {
        print('${AnsiColors.yellow}Invalid selection.${AnsiColors.reset}');
      }
    } else if (input == '3') {
      stdout.write('Environment number to edit branch: ');
      final idx = int.tryParse(stdin.readLineSync() ?? '');
      if (idx != null && idx > 0 && idx <= envs.length) {
        final key = envs.keys.elementAt(idx - 1);
        print('Current branch: ${envs[key] ?? ""}');
        stdout.write('New branch: ');
        final branch = stdin.readLineSync()?.trim();
        if (branch != null && branch.isNotEmpty) {
          envs[key] = branch;
          await _writeEnvironments(envs);
          print('${AnsiColors.green}Branch for environment "$key" updated.${AnsiColors.reset}');
        } else {
          print('${AnsiColors.yellow}Invalid branch.${AnsiColors.reset}');
        }
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

Future<Map<String, String>> _readEnvironments() async {
  final file = File(_envFilePath);
  if (!file.existsSync()) return {};
  try {
    final content = await file.readAsString();
    final map = loadYaml(content);
    if (map is Map) {
      return Map<String, String>.from(map);
    }
    return {};
  } catch (_) {
    return {};
  }
}

Future<void> _writeEnvironments(Map<String, String> envs) async {
  final file = File(_envFilePath);
  final writer = YamlWriter();
  await file.writeAsString(writer.write(envs));
}
