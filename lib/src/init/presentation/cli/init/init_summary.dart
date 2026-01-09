import 'package:shepherd/src/domains/data/datasources/local/domains_database.dart';

Future<void> printInitSummary(DomainsDatabase db, String? domainName, String repoType) async {
  print('\n--- Shepherd project initialized! ---');
  print('Repository type: $repoType');

  if (domainName != null) {
    print('Domain: $domainName');
    final owners = await db.getOwnersForDomain(domainName);
    print('Owners:');
    for (final o in owners) {
      print('  - [1m${o['first_name']} ${o['last_name']} <${o['email']}>[0m (${o['type']})'
          '${o['github_username'] != null && (o['github_username'] as String).isNotEmpty ? ' [GitHub: ${o['github_username']}]' : ''}');
    }
  } else {
    print('Mode: Automation Only (No initial domain registered)');
  }

  print('\nYou can edit domains, owners, or config later using the regular menus.');
}
