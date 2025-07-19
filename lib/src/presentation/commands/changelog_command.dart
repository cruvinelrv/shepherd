import 'dart:io';

import 'package:shepherd/src/domain/services/changelog_service.dart';

Future<void> runChangelogCommand() async {
  try {
    final service = ChangelogService();
    await service.updateChangelog();
    print('CHANGELOG.md successfully updated!');
  } catch (e) {
    print('Error updating changelog: $e');
    exit(1);
  }
}
