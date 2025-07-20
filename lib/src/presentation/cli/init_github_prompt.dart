import 'package:shepherd/src/presentation/cli/input_utils.dart';

import '../../data/datasources/local/shepherd_database.dart';

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
