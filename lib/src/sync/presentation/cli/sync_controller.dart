import 'dart:io';
import 'package:shepherd/src/sync/domain/services/yaml_db_consistency_checker.dart';

class SyncController {
  Future<void> checkAndSyncYamlDbConsistency(String projectPath) async {
    try {
      final isConsistent = await checkYamlDbConsistency(projectPath);
      if (!isConsistent) {
        print('\nThe following files are required for synchronization:');
        stdout.write(
            'YAML files are not consistent with shepherd.db. Do you want to run "shepherd pull" to synchronize? (y/N): ');
        final resp = stdin.readLineSync()?.trim().toLowerCase();
        if (_isYes(resp)) {
          await Process.run('shepherd', ['pull']);
          print('Synchronization completed.');
        }
      }
    } catch (e) {
      // ignore
    }
  }

  bool _isYes(String? resp) {
    if (resp == null) return false;
    return resp == 'y' || resp == 'yes' || resp == 's' || resp == 'sim';
  }
}
