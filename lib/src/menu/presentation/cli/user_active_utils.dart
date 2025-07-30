import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/data/datasources/local/config_database.dart';

const userActivePath = 'dev_tools/shepherd/user_active.yaml';

Future<Map<String, dynamic>?> readActiveUser() async {
  final file = File(userActivePath);
  if (!await file.exists()) return null;
  final content = await file.readAsString();
  if (content.trim().isEmpty) return null;
  final loaded = loadYaml(content);
  if (loaded is YamlMap) {
    return Map<String, dynamic>.from(loaded);
  }
  return null;
}

Future<void> writeActiveUser(Map<String, dynamic> user) async {
  final file = File(userActivePath);
  await file.parent.create(recursive: true);
  final buffer = StringBuffer();
  user.forEach((key, value) {
    buffer.writeln('$key: "$value"');
  });
  await file.writeAsString(buffer.toString());
}

Future<Map<String, dynamic>> selectAndSetActiveUser(ConfigDatabase db) async {
  final persons = await db.getAllPersons();
  if (persons.isEmpty) {
    throw Exception('No users registered in Shepherd.');
  }
  print('\nSelect the active user:');
  for (var i = 0; i < persons.length; i++) {
    final p = persons[i];
    print('${i + 1}. ${p['first_name']} ${p['last_name']} (${p['email']})');
  }
  int? idx;
  do {
    stdout.write('Enter the number of the user to activate: ');
    final input = stdin.readLineSync();
    idx = int.tryParse(input ?? '');
    if (idx == null || idx < 1 || idx > persons.length) {
      print('Invalid option.');
      idx = null;
    }
  } while (idx == null);
  final user = persons[idx - 1];
  await writeActiveUser(user);
  return user;
}
