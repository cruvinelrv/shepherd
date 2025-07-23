import 'dart:io';

import 'package:shepherd/src/tools/domain/services/changelog_service.dart';

Future<void> runChangelogCommand() async {
  stdout.write('Do you want to update the CHANGELOG.md? (y/n): ');
  final resp = stdin.readLineSync()?.trim().toLowerCase();
  if (resp != 'y' && resp != 'yes' && resp != 's' && resp != 'sim') {
    print('CHANGELOG.md update skipped.');
    return;
  }
  try {
    final service = ChangelogService();
    final result = await service.updateChangelog();
    if (result == true) {
      print('CHANGELOG.md successfully updated!');
    } else if (result == false) {
      print(
          'Entry for this branch and version already exists. No changes made.');
    } else {
      // result == null: environment branch
      print(
          'To update the changelog, you must first create a branch for your activity.');
    }
  } catch (e) {
    print('Error updating changelog: $e');
    exit(1);
  }
}
