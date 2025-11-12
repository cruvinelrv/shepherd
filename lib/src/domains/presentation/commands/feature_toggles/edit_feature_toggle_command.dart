import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/enhanced_feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/enhanced_feature_toggle_entity.dart';

Future<void> runEditFeatureToggleCommand() async {
  print('✏️ Editando Feature Toggle\n');

  final db = EnhancedFeatureToggleDatabase(Directory.current.path);

  // Show list of feature toggles for user to choose from
  final toggles = await db.getAllFeatureToggles();

  if (toggles.isEmpty) {
    print('❌ No feature toggles found.');
    print('💡 Use the "Add Feature Toggle" command to create the first one.');
    return;
  }

  print('📋 Available Feature Toggles:');
  for (final toggle in toggles) {
    final status = toggle.enabled ? '✅' : '❌';
    print('   $status [${toggle.id}] ${toggle.name} - ${toggle.domain}');
  }

  stdout.write('\nEnter the feature toggle ID to edit: ');
  final idInput = stdin.readLineSync();
  final id = int.tryParse(idInput ?? '');

  if (id == null) {
    print('❌ Invalid ID.');
    return;
  }

  // Find existing feature toggle
  final existingToggle = toggles.where((t) => t.id == id).firstOrNull;
  if (existingToggle == null) {
    print('❌ Feature toggle with ID $id not found.');
    return;
  }

  print('\n🔍 Current Feature Toggle:');
  print('   Name: ${existingToggle.name}');
  print('   Status: ${existingToggle.enabled ? 'Enabled' : 'Disabled'}');
  print('   Domain: ${existingToggle.domain}');
  print('   Description: ${existingToggle.description}');
  if (existingToggle.team != null) print('   Team: ${existingToggle.team}');
  if (existingToggle.activity != null) {
    print('   Activity: ${existingToggle.activity}');
  }

  print('\n📝 Enter new values (press Enter to keep current):');

  // Required fields
  stdout.write('Name [${existingToggle.name}]: ');
  final nameInput = stdin.readLineSync()?.trim();
  final name = nameInput?.isNotEmpty == true ? nameInput! : existingToggle.name;

  stdout.write('Enabled? (y/n) [${existingToggle.enabled ? 'y' : 'n'}]: ');
  final enabledInput = stdin.readLineSync()?.toLowerCase().trim();
  bool enabled;
  if (enabledInput?.isNotEmpty == true) {
    enabled = enabledInput == 'y' || enabledInput == 's';
  } else {
    enabled = existingToggle.enabled;
  }

  stdout.write('Domain [${existingToggle.domain}]: ');
  final domainInput = stdin.readLineSync()?.trim();
  final domain =
      domainInput?.isNotEmpty == true ? domainInput! : existingToggle.domain;

  stdout.write('Description [${existingToggle.description}]: ');
  final descriptionInput = stdin.readLineSync()?.trim();
  final description = descriptionInput?.isNotEmpty == true
      ? descriptionInput!
      : existingToggle.description;

  // Optional fields (enterprise)
  stdout.write('Team [${existingToggle.team ?? 'not defined'}]: ');
  final teamInput = stdin.readLineSync()?.trim();
  final team = teamInput?.isNotEmpty == true ? teamInput : existingToggle.team;

  stdout.write('Activity [${existingToggle.activity ?? 'not defined'}]: ');
  final activityInput = stdin.readLineSync()?.trim();
  final activity = activityInput?.isNotEmpty == true
      ? activityInput
      : existingToggle.activity;

  stdout.write('Prototype [${existingToggle.prototype ?? 'not defined'}]: ');
  final prototypeInput = stdin.readLineSync()?.trim();
  final prototype = prototypeInput?.isNotEmpty == true
      ? prototypeInput
      : existingToggle.prototype;

  // Create updated entity
  final updatedToggle = EnhancedFeatureToggleEntity(
    id: existingToggle.id,
    name: name,
    enabled: enabled,
    domain: domain,
    description: description,
    team: team,
    activity: activity,
    prototype: prototype,
    ignoreDocs: existingToggle.ignoreDocs,
    ignoreBundleNames: existingToggle.ignoreBundleNames,
    blockBundleNames: existingToggle.blockBundleNames,
    minVersion: existingToggle.minVersion,
    maxVersion: existingToggle.maxVersion,
    createdAt: existingToggle.createdAt,
    updatedAt: DateTime.now(),
  );

  // Save to database
  await db.updateFeatureToggleById(id, updatedToggle);

  print('\n✅ Feature toggle "$name" updated successfully!');
}
