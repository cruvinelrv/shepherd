import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

const String microfrontendsYamlPath = '.shepherd/microfrontends.yaml';

List<Map<String, dynamic>> loadMicrofrontends() {
  final file = File(microfrontendsYamlPath);
  if (!file.existsSync()) return [];
  final doc = loadYaml(file.readAsStringSync());
  if (doc is YamlMap && doc['microfrontends'] is YamlList) {
    return List<Map<String, dynamic>>.from(
      (doc['microfrontends'] as YamlList).map((e) => Map<String, dynamic>.from(e)),
    );
  }
  return [];
}

void _saveMicrofrontends(List<Map<String, dynamic>> microfrontends) {
  final writer = YamlWriter();
  final yamlString = writer.write({'microfrontends': microfrontends});
  File(microfrontendsYamlPath).writeAsStringSync(yamlString);
}

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
        final microfrontends = loadMicrofrontends();
        if (microfrontends.isEmpty) {
          print('No microfrontends registered.');
        } else {
          print('Registered microfrontends:');
          for (var i = 0; i < microfrontends.length; i++) {
            final m = microfrontends[i];
            print('  ${i + 1}. ${m['name']} (${m['path'] ?? '-'})');
            if (m['description'] != null) print('     ${m['description']}');
          }
        }
        break;
      case '2':
        stdout.write('Enter microfrontend name: ');
        final name = stdin.readLineSync()?.trim();
        if (name == null || name.isEmpty) {
          print('Name cannot be empty.');
          break;
        }
        stdout.write('Enter path (relative to project root): ');
        final path = stdin.readLineSync()?.trim();
        stdout.write('Enter description (optional): ');
        final description = stdin.readLineSync()?.trim();
        final microfrontends = loadMicrofrontends();
        if (microfrontends.any((m) => m['name'] == name)) {
          print('A microfrontend with this name already exists.');
          break;
        }
        microfrontends.add({
          'name': name,
          if (path != null && path.isNotEmpty) 'path': path,
          if (description != null && description.isNotEmpty) 'description': description,
        });
        _saveMicrofrontends(microfrontends);
        print('Microfrontend "$name" added.');
        break;
      case '3':
        final microfrontends = loadMicrofrontends();
        if (microfrontends.isEmpty) {
          print('No microfrontends to remove.');
          break;
        }
        print('Registered microfrontends:');
        for (var i = 0; i < microfrontends.length; i++) {
          final m = microfrontends[i];
          print('  ${i + 1}. ${m['name']} (${m['path'] ?? '-'})');
        }
        stdout.write('Enter the number or name of the microfrontend to remove: ');
        final input = stdin.readLineSync()?.trim();
        int? idx;
        if (input == null || input.isEmpty) {
          print('No input provided.');
          break;
        }
        idx = int.tryParse(input);
        if (idx != null && idx > 0 && idx <= microfrontends.length) {
          final removed = microfrontends.removeAt(idx - 1);
          _saveMicrofrontends(microfrontends);
          print('Removed microfrontend: \'${removed['name']}\'.');
        } else {
          final i = microfrontends.indexWhere((m) => m['name'] == input);
          if (i == -1) {
            print('Microfrontend not found.');
          } else {
            final removed = microfrontends.removeAt(i);
            _saveMicrofrontends(microfrontends);
            print('Removed microfrontend: \'${removed['name']}\'.');
          }
        }
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
