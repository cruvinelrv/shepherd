import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import 'input_utils.dart';

Future<void> registerSquadFlow() async {
  final squadsFile = File('.shepherd/domains.yaml');
  if (!squadsFile.existsSync()) {
    print('domains.yaml not found. Cannot register squad.');
    return;
  }
  final yamlContent = squadsFile.readAsStringSync();
  final yaml = loadYaml(yamlContent);
  final domains = (yaml['domains'] as List?)?.toList() ?? [];
  // Collect all unique owners
  final owners = <Map<String, dynamic>>[];
  for (final domain in domains) {
    final domainOwners = domain['owners'] as List?;
    if (domainOwners != null) {
      for (final owner in domainOwners) {
        if (owner is Map && !owners.any((o) => o['email'] == owner['email'])) {
          owners.add(Map<String, dynamic>.from(owner));
        }
      }
    }
  }
  if (owners.isEmpty) {
    print('No owners found. Please add owners before creating a squad.');
    return;
  }
  stdout.write('Enter squad name: ');
  final squadName = stdin.readLineSync()?.trim();
  if (squadName == null || squadName.isEmpty) {
    print('Invalid squad name.');
    return;
  }
  print('Select owners for this squad (comma separated numbers):');
  for (var i = 0; i < owners.length; i++) {
    final o = owners[i];
    print('  [${i + 1}] ${o['first_name']} ${o['last_name']} <${o['email']}>');
  }
  stdout.write('Enter numbers: ');
  final input = stdin.readLineSync();
  final selected = <Map<String, dynamic>>[];
  if (input != null && input.trim().isNotEmpty) {
    final nums = input
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .where((n) => n != null && n > 0 && n <= owners.length)
        .toSet();
    for (final n in nums) {
      selected.add(owners[n! - 1]);
    }
  }
  if (selected.isEmpty) {
    print('No owners selected. Squad not created.');
    return;
  }
  // Add squad to YAML
  final squads = (yaml['squads'] as List?)?.toList() ?? [];
  final memberEmails = selected
      .map((o) => o['email'])
      .where((email) => email != null && email.toString().trim().isNotEmpty)
      .toList();
  squads.add({
    'name': squadName,
    'members': memberEmails,
  });
  // Update YAML
  final updated = Map<String, dynamic>.from(yaml);
  updated['squads'] = squads;
  final writer = YamlWriter();
  squadsFile.writeAsStringSync(writer.write(updated), mode: FileMode.write);
  print('Squad "$squadName" registered with ${selected.length} member(s).');
}

Future<void> showSquadsMenu() async {
  while (true) {
    print('\n========== SQUADS MANAGEMENT ==========');
    print('''
  1. Register new squad
  2. List squads
  3. Edit squad (not implemented)
  4. Delete squad (not implemented)
  0. Return to domains menu
''');
    stdout.write('Select an option: ');
    final input = stdin.readLineSync();
    switch (input?.trim()) {
      case '1':
        await registerSquadFlow();
        pauseForEnter();
        break;
      case '2':
        await listSquadsFlow();
        pauseForEnter();
        break;
      case '3':
        print('Edit squad - Not implemented yet.');
        pauseForEnter();
        break;
      case '4':
        print('Delete squad - Not implemented yet.');
        pauseForEnter();
        break;
      case '0':
        print('Returning to domains menu...');
        return;
      default:
        print('Invalid option. Please try again.');
        pauseForEnter();
    }
    print('\n----------------------------------------------\n');
  }
}

Future<void> listSquadsFlow() async {
  final squadsFile = File('.shepherd/domains.yaml');
  if (!squadsFile.existsSync()) {
    print('domains.yaml not found.');
    return;
  }
  final yamlContent = squadsFile.readAsStringSync();
  final yaml = loadYaml(yamlContent);
  final squads = (yaml['squads'] as List?)?.toList() ?? [];
  if (squads.isEmpty) {
    print('No squads found.');
    return;
  }
  print('Registered squads:');
  for (var i = 0; i < squads.length; i++) {
    final squad = squads[i] as Map;
    final name = squad['name'] ?? 'Unnamed';
    String members = '(no members)';
    final rawMembers = squad['members'];
    if (rawMembers is List && rawMembers.isNotEmpty) {
      members = rawMembers.join(', ');
    } else if (rawMembers is String && rawMembers.trim().isNotEmpty) {
      members = rawMembers;
    }
    print('  [${i + 1}] $name - Members: $members');
  }
}
