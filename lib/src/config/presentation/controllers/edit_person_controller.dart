import 'dart:io';
import 'package:shepherd/src/config/data/datasources/local/config_database.dart';

/// Controller for editing a person's/owner's data
class EditPersonController {
  final ConfigDatabase db;
  EditPersonController(this.db);

  Future<void> run() async {
    final persons = await db.getAllPersons();
    if (persons.isEmpty) {
      print('No persons registered.');
      return;
    }
    print('Registered persons:');
    for (var i = 0; i < persons.length; i++) {
      final p = persons[i];
      print(
          '  [${i + 1}] ${p['first_name']} ${p['last_name']} <${p['email']}> (${p['type']})${p['github_username'] != null && (p['github_username'] as String).isNotEmpty ? ' [GitHub: ${p['github_username']}]' : ''}');
    }
    stdout.write('Enter the number of the person you want to edit: ');
    final input = stdin.readLineSync();
    final idx = int.tryParse(input ?? '');
    if (idx == null || idx < 1 || idx > persons.length) {
      print('Invalid input.');
      return;
    }
    final person = persons[idx - 1];
    print('Editing: ${person['first_name']} ${person['last_name']} <${person['email']}>');
    stdout.write('New GitHub username (leave blank to keep current): ');
    final newGithub = stdin.readLineSync()?.trim();
    if (newGithub == null || newGithub.isEmpty) {
      print('Nothing changed.');
      return;
    }
    await db.updatePersonGithubUsername(person['id'] as int, newGithub);
    print('GitHub username updated successfully!');
  }
}
