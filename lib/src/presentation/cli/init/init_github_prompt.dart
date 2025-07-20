import 'package:shepherd/src/data/shepherd_database.dart';
import '../input_utils.dart';

Future<void> ensureGithubUsernames(ShepherdDatabase db) async {
  print('\n--- GitHub usernames for owners ---');
  final persons = await db.getAllPersons();
  for (final p in persons) {
    final gh = (p['github_username'] ?? '').toString().trim();
    if (gh.isEmpty) {
      print('Owner: [1m${p['first_name']} ${p['last_name']} <${p['email']}>[0m');
      final newGh = readLinePrompt('GitHub username: ');
      if (newGh != null && newGh.trim().isNotEmpty) {
        await db.updatePersonGithubUsername(p['id'] as int, newGh.trim());
      }
    }
  }
  print('All owners now have GitHub usernames.');
}
