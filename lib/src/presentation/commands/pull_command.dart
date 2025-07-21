import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:shepherd/src/sync/data/datasources/local/sync_database.dart';
import '../cli/user_active_utils.dart';

/// Runs the shepherd pull command: prompts for active user, saves to user_active.yaml,
/// and imports domains.yaml into shepherd.db.
Future<void> runPullCommand(List<String> args) async {
  // 1. Prompt for active user
  stdout.write('Enter the active user name: ');
  final user = stdin.readLineSync()?.trim();
  if (user == null || user.isEmpty) {
    print('User not specified. Aborting.');
    return;
  }

  // 2. Read domains.yaml
  final domainsFile = File(p.join('devops', 'domains.yaml'));
  if (!await domainsFile.exists()) {
    print('domains.yaml not found in devops/. Aborting.');
    return;
  }
  final yamlContent = await domainsFile.readAsString();
  final yaml = loadYaml(yamlContent);
  final domainsList = (yaml['domains'] as List?)?.toList();
  if (domainsList == null) {
    print('No domains found in domains.yaml. Aborting.');
    return;
  }

  // 3. Check if user exists as owner
  Map<String, dynamic>? foundOwner;
  // String? foundDomain; // removido, não utilizado
  for (final domain in domainsList) {
    final owners = domain['owners'] as List?;
    if (owners != null) {
      for (final owner in owners) {
        if ((owner['first_name']?.toString().toLowerCase() == user.toLowerCase()) ||
            (owner['last_name']?.toString().toLowerCase() == user.toLowerCase()) ||
            (owner['email']?.toString().toLowerCase() == user.toLowerCase()) ||
            (owner['github_username']?.toString().toLowerCase() == user.toLowerCase())) {
          foundOwner = Map<String, dynamic>.from(owner);
          break;
        }
      }
    }
    if (foundOwner != null) break;
  }

  if (foundOwner == null) {
    print('User not found as owner in domains.yaml. Let\'s create a new owner.');
    // Prompt for owner details
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
    // Choose domain to add the new owner
    print('Available domains:');
    for (var i = 0; i < domainsList.length; i++) {
      print('  [${i + 1}] ${domainsList[i]['name']}');
    }
    stdout.write('Select domain number to add this owner: ');
    final domainIdxStr = stdin.readLineSync()?.trim();
    int domainIdx = int.tryParse(domainIdxStr ?? '') ?? 1;
    if (domainIdx < 1 || domainIdx > domainsList.length) domainIdx = 1;
    final domainYaml = domainsList[domainIdx - 1];
    // Convert domain to a modifiable Dart map
    final domain = Map<String, dynamic>.from(domainYaml);
    // Convert owners to a modifiable Dart list
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
    // Replace the domain in domainsList with the updated map
    domainsList[domainIdx - 1] = domain;
    // Update domains.yaml
    final updatedYaml = {'domains': domainsList};
    // Serialize to YAML
    final yamlString = _toYamlString(updatedYaml);
    await domainsFile.writeAsString(yamlString);
    print('New owner added to domains.yaml.');
    foundOwner = newOwner;
  }

  // 4. Save to user_active.yaml using the utility for full user object
  await writeActiveUser(foundOwner);
  print('Active user saved to user_active.yaml.');

  // 5. Import into shepherd.db
  final updatedYamlContent = await domainsFile.readAsString();
  final updatedYaml = loadYaml(updatedYamlContent);
  final db = SyncDatabase(Directory.current.path);
  await db.importFromYaml(updatedYaml);
  // Also import user stories and tasks from shepherd_activity.yaml
  await db.importActivitiesFromYaml();
  await db.close();
  print('shepherd.db created/updated from domains.yaml and shepherd_activity.yaml.');
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
