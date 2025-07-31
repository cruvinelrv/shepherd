import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:shepherd/src/sync/data/datasources/local/sync_database.dart';
import 'package:shepherd/src/sync/presentation/commands/sync_config.dart';
import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';
import 'package:shepherd/src/sync/domain/services/feature_toggle_exporter.dart';
import '../../../menu/presentation/cli/user_active_utils.dart';

/// Runs the shepherd pull command: prompts for active user, saves to user_active.yaml,
/// and imports domains.yaml into shepherd.db.

Future<void> runPullCommand(List<String> args) async {
  // Ensure execution in the project root
  final shepherdDir = Directory(p.join(Directory.current.path, '.shepherd'));
  if (!shepherdDir.existsSync()) {
    print(
        '\x1B[31mShepherd pull must be run from the project root (where the .shepherd folder exists).\x1B[0m');
    print('Current directory: \'${Directory.current.path}\'');
    return;
  }

  // Check all required YAML files from config
  for (final config in syncedFiles) {
    final file = File(p.join(Directory.current.path, config.path));
    if (config.requiredSync && !file.existsSync()) {
      print('Required file missing: ${config.path}');
      // Recria feature_toggles.yaml a partir do banco
      if (config.path.endsWith('feature_toggles.yaml')) {
        print('Regenerating feature_toggles.yaml from database...');
        final db = FeatureToggleDatabase(Directory.current.path);
        await exportFeatureTogglesToYaml(db, Directory.current.path);
        print('feature_toggles.yaml regenerated.');
      }
      // Aqui você pode adicionar lógica para outros arquivos, se necessário
    }
  }

  // Prompt for active user
  stdout.write('Enter the active user name: ');
  final user = stdin.readLineSync()?.trim();
  if (user == null || user.isEmpty) {
    print('User not specified. Aborting.');
    return;
  }

  // Import logic for each YAML file (example for domains.yaml)
  // You can expand this logic for other YAMLs as needed
  final domainsFile = File(p.join('devops', 'domains.yaml'));
  if (!await domainsFile.exists()) {
    print('domains.yaml not found in devops/.');
    print(
        'No project configuration found. Launching shepherd init to configure a new project...');
    try {
      final result = await Process.start('shepherd', ['init']);
      await stdout.addStream(result.stdout);
      await stderr.addStream(result.stderr);
      final exitCode = await result.exitCode;
      if (exitCode != 0) {
        print(
            'shepherd init did not complete successfully. Please check the output above.');
      } else {
        print('shepherd init completed. You can now re-run shepherd pull.');
      }
    } catch (e) {
      print(
          'Failed to launch shepherd init automatically. Please run "shepherd init" manually.');
    }
    return;
  }
  final yamlContent = await domainsFile.readAsString();
  final yaml = loadYaml(yamlContent);
  final domainsList = (yaml['domains'] as List?)?.toList();
  if (domainsList == null) {
    print('No domains found in domains.yaml. Aborting.');
    return;
  }

  // Check if user exists as owner
  Map<String, dynamic>? foundOwner;
  for (final domain in domainsList) {
    final owners = domain['owners'] as List?;
    if (owners != null) {
      for (final owner in owners) {
        if ((owner['first_name']?.toString().toLowerCase() ==
                user.toLowerCase()) ||
            (owner['last_name']?.toString().toLowerCase() ==
                user.toLowerCase()) ||
            (owner['email']?.toString().toLowerCase() == user.toLowerCase()) ||
            (owner['github_username']?.toString().toLowerCase() ==
                user.toLowerCase())) {
          foundOwner = Map<String, dynamic>.from(owner);
          break;
        }
      }
    }
    if (foundOwner != null) break;
  }

  if (foundOwner == null) {
    print(
        'User not found as owner in domains.yaml. Let\'s create a new owner.');
    stdout.write('First name: ');
    final firstName = stdin.readLineSync()?.trim() ?? '';
    stdout.write('Last name: ');
    final lastName = stdin.readLineSync()?.trim() ?? '';
    stdout.write('Email: ');
    final email = stdin.readLineSync()?.trim() ?? '';
    stdout.write('Type (developer/lead/etc): ');
    final type = stdin.readLineSync()?.trim() ?? '';
    stdout.write('GitHub username: ');
    final githubUsername = stdin.readLineSync()?.trim() ?? '';
    print('Available domains:');
    for (var i = 0; i < domainsList.length; i++) {
      print('  [${i + 1}] ${domainsList[i]['name']}');
    }
    stdout.write('Select domain number to add this owner: ');
    final domainIdxStr = stdin.readLineSync()?.trim();
    int domainIdx = int.tryParse(domainIdxStr ?? '') ?? 1;
    if (domainIdx < 1 || domainIdx > domainsList.length) domainIdx = 1;
    final domainYaml = domainsList[domainIdx - 1];
    final domain = Map<String, dynamic>.from(domainYaml);
    final owners = (domain['owners'] as List? ?? []).toList();
    final newOwner = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'type': type,
      'github_username': githubUsername,
    };
    owners.add(newOwner);
    domain['owners'] = owners;
    domainsList[domainIdx - 1] = domain;
    final updatedYaml = {'domains': domainsList};
    final yamlString = _toYamlString(updatedYaml);
    await domainsFile.writeAsString(yamlString);
    print('New owner added to domains.yaml.');
    foundOwner = newOwner;
  }

  await writeActiveUser(foundOwner);
  print('Active user saved to user_active.yaml.');

  final updatedYamlContent = await domainsFile.readAsString();
  final updatedYaml = loadYaml(updatedYamlContent);
  final db = SyncDatabase(Directory.current.path);
  await db.importFromYaml(updatedYaml);
  await db.importActivitiesFromYaml();
  await db.close();
  print(
      'shepherd.db created/updated from domains.yaml and shepherd_activity.yaml.');
}

// Simple function to serialize Map to YAML (for domains.yaml only)
String _toYamlString(Map data) {
  final buffer = StringBuffer();
  buffer.writeln('domains:');
  final domains = data['domains'] as List? ?? [];
  for (final domain in domains) {
    buffer.writeln('  - name: "${domain['name']}"');
    buffer.writeln('    owners:');
    final owners = domain['owners'] as List? ?? [];
    for (final owner in owners) {
      buffer.writeln('      - first_name: "${owner['first_name']}"');
      buffer.writeln('        last_name: "${owner['last_name']}"');
      buffer.writeln('        email: "${owner['email']}"');
      buffer.writeln('        type: "${owner['type']}"');
      buffer.writeln('        github_username: "${owner['github_username']}"');
    }
    buffer.writeln('    warnings: []');
  }
  return buffer.toString();
}
