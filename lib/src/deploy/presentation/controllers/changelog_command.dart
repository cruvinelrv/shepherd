import 'dart:io';
import 'package:shepherd/src/tools/domain/services/changelog_service.dart';

Future<void> runChangelogCommand() async {
  stdout.write('Do you want to update the CHANGELOG.md? (y/n): ');
  final resp = stdin.readLineSync()?.trim().toLowerCase();
  if (resp != 'y' && resp != 'yes') {
    print('CHANGELOG.md update skipped.');
    return;
  }
  try {
    final service = ChangelogService();
    // add print for debug
    print('[DEBUG] Running updateChangelog...');
    final updatedDirs = await service.updateChangelog();
    print('[DEBUG] updateChangelog finished.');
    if (updatedDirs.isNotEmpty) {
      print('CHANGELOG.md successfully updated for:');
      for (final dir in updatedDirs) {
        print('  - $dir');
      }
      print(
          '[DEBUG] See above for updated directories and extracted commits (if any).');
    } else {
      // Only print message if not environment branch, to ensure it doesn't appear duplicated
      // The blocking message has already been printed by the service
    }
  } catch (e) {
    print('Error updating changelog: $e');
    exit(1);
  }
}
