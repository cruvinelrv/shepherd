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
    final updatedDirs = await service.updateChangelog();
    if (updatedDirs.isNotEmpty) {
      print('CHANGELOG.md successfully updated for:');
      for (final dir in updatedDirs) {
        print('  - $dir');
      }
    } else {
      print('To update the changelog, you must first create a branch for your activity.');
    }
  } catch (e) {
    print('Error updating changelog: $e');
    exit(1);
  }
}
