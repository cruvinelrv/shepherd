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
      // ignore error
    }
  }

  bool _isYes(String? resp) {
    if (resp == null) return false;
    return resp == 'y' || resp == 'yes';
  }

  Future<void> ensureActiveUser() async {
    final userActiveFile = File('.shepherd/user_active.yaml');
    final hasUser =
        userActiveFile.existsSync() && userActiveFile.lengthSync() > 0;
    if (!hasUser) {
      print('No active user found.');
      stdout.write(
          'Do you want to register a new user (1) or initialize with default user (2)? [1/2]: ');
      final choice = stdin.readLineSync()?.trim();
      if (choice == '1') {
        stdout.write('Enter user id: ');
        final id = stdin.readLineSync()?.trim() ?? 'default';
        stdout.write('Enter first name: ');
        final firstName = stdin.readLineSync()?.trim() ?? 'Default';
        stdout.write('Enter last name: ');
        final lastName = stdin.readLineSync()?.trim() ?? 'User';
        stdout.write('Enter email: ');
        final email = stdin.readLineSync()?.trim() ?? 'default@shepherd.local';
        stdout.write('Enter type (owner/administrator): ');
        final type = stdin.readLineSync()?.trim() ?? 'owner';
        stdout.write('Enter github username: ');
        final github = stdin.readLineSync()?.trim() ?? 'defaultuser';
        final userYaml = 'id: "$id"\n'
            'first_name: "$firstName"\n'
            'last_name: "$lastName"\n'
            'email: "$email"\n'
            'type: "$type"\n'
            'github_username: "$github"\n';
        await userActiveFile.writeAsString(userYaml);
        print('user_active.yaml initialized with custom user.');
      } else if (choice == '2') {
        final defaultUser = 'id: "default"\n'
            'first_name: "Default"\n'
            'last_name: "User"\n'
            'email: "default@shepherd.local"\n'
            'type: "owner"\n'
            'github_username: "defaultuser"\n';
        await userActiveFile.writeAsString(defaultUser);
        print('user_active.yaml initialized with default user.');
      } else {
        print(
            'No user initialized. You can run shepherd again to set up an active user.');
        exit(0);
      }
    }
  }
}
