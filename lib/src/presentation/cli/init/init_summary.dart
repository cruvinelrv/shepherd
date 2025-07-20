import 'package:shepherd/src/data/shepherd_database.dart';

Future<void> printInitSummary(ShepherdDatabase db, String domainName, String repoType) async {
  print('\n--- Shepherd project initialized! ---');
  print('Domain: $domainName');
  print('Repository type: $repoType');
  final owners = await db.getOwnersForDomain(domainName);
  print('Owners:');
  for (final o in owners) {
    print('  - [1m${o['first_name']} ${o['last_name']} <${o['email']}>[0m (${o['type']})'
        '${o['github_username'] != null && (o['github_username'] as String).isNotEmpty ? ' [GitHub: ${o['github_username']}]' : ''}');
  }
  print('\nYou can edit domains, owners, or config later using the regular menus.');
}
