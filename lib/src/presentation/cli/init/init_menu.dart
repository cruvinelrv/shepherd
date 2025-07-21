import 'dart:io';

import '../../../data/datasources/local/shepherd_database.dart';
import 'init_domain_prompt.dart';
import 'init_owner_prompt.dart';
import 'init_repo_type_prompt.dart';
import 'init_github_prompt.dart';
import 'init_summary.dart';
import 'init_cancel_exception.dart';

Future<void> showInitMenu() async {
  print('\n================ SHEPHERD INIT ================\n');
  print('You can type 9 at any prompt to return to the main menu.');
  final db = ShepherdDatabase(Directory.current.path);

  try {
    // 1. Domain registration
    final domainName = await promptDomainName(allowCancel: true);
    if (domainName == null) throw ShepherdInitCancelled();

    // 2. Create domain immediately (with no owners yet)
    final existingDomains = await db.getAllDomainHealths();
    final alreadyExists =
        existingDomains.any((d) => d.domainName == domainName);
    if (!alreadyExists) {
      await db.insertDomain(
        domainName: domainName,
        score: 0.0,
        commits: 0,
        days: 0,
        warnings: '',
        personIds: [],
        projectPath: Directory.current.path,
      );
      print('Domain "$domainName" registered in database.');
    }

    // 3. Owner registration
    print('--- Owner registration ---');
    await promptOwners(db, domainName, allowCancel: true);

    // 4. Repository type selection and save
    final repoType = await promptRepoTypeAndSave(allowCancel: true);
    if (repoType == null) throw ShepherdInitCancelled();

    // 5. If GitHub, ensure owners have github_username
    if (repoType == 'github') {
      await ensureGithubUsernames(db, allowCancel: true);
    }

    // 6. Final summary
    await printInitSummary(db, domainName, repoType);
  } on ShepherdInitCancelled {
    print('Init cancelled. Returning to main menu.');
    return;
  }
}
