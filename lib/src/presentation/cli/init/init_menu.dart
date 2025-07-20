import 'dart:io';
import 'package:shepherd/src/data/shepherd_database.dart';

import 'init_domain_prompt.dart';
import 'init_owner_prompt.dart';
import 'init_repo_type_prompt.dart';
import 'init_github_prompt.dart';
import 'init_summary.dart';

Future<void> showInitMenu() async {
  print('\n================ SHEPHERD INIT ================\n');
  final db = ShepherdDatabase(Directory.current.path);

  // 1. Domain registration
  final domainName = await promptDomainName();

  // 2. Owner registration
  print('\n--- Owner registration ---');
  await promptOwners(db, domainName);

  // 3. Register domain in domain_health table if it does not exist
  final existingDomains = await db.getAllDomainHealths();
  final alreadyExists = existingDomains.any((d) => d.domainName == domainName);
  if (!alreadyExists) {
    final owners = await db.getOwnersForDomain(domainName);
    final ownerIds = owners.map((o) => o['id'] as int).toList();
    await db.insertDomain(
      domainName: domainName,
      score: 0.0,
      commits: 0,
      days: 0,
      warnings: '',
      personIds: ownerIds,
      projectPath: Directory.current.path,
    );
    print('Domain "$domainName" registered in database.');
  }

  // 4. Repository type selection and save
  final repoType = await promptRepoTypeAndSave();

  // 5. If GitHub, ensure owners have github_username
  if (repoType == 'github') {
    await ensureGithubUsernames(db);
  }

  // 6. Final summary
  await printInitSummary(db, domainName, repoType);
}
