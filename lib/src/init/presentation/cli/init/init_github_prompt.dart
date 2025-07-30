import 'package:shepherd/src/menu/presentation/cli/input_utils.dart';
import '../../../../domains/data/datasources/local/domains_database.dart';
import 'package:shepherd/src/config/data/datasources/local/config_database.dart';
import 'init_cancel_exception.dart';

Future<bool> ensureGithubUsernames(
    DomainsDatabase domainsDb, ConfigDatabase configDb,
    {bool allowCancel = false}) async {
  print('\n--- GitHub usernames for owners ---');
  final persons = await configDb.getAllPersons();
  for (final p in persons) {
    final gh = (p['github_username'] ?? '').toString().trim();
    if (gh.isEmpty) {
      print(
          'Owner: \u001b[1m${p['first_name']} ${p['last_name']} <${p['email']}>\u001b[0m');
      final newGh = readLinePrompt(
          'GitHub username${allowCancel ? " (0/9 to cancel)" : ""}: ');
      if (newGh == null) continue;
      if (allowCancel &&
          (newGh.trim() == '0' ||
              newGh.trim() == '9' ||
              newGh.trim().toLowerCase() == 'q')) {
        throw ShepherdInitCancelled();
      }
      if (newGh.trim().isNotEmpty) {
        await configDb.updatePersonGithubUsername(p['id'] as int, newGh.trim());
      }
    }
  }
  print('All owners now have GitHub usernames.');
  return true;
}
