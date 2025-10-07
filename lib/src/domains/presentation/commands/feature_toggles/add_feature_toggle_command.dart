import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/enhanced_feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/enhanced_feature_toggle_entity.dart';

Future<void> runAddFeatureToggleCommand() async {
  print('🚀 Adicionando Feature Toggle\n');

  // Required fields
  stdout.write('Feature Toggle Name: ');
  final name = stdin.readLineSync() ?? '';

  stdout.write('Enabled? (y/n): ');
  final enabledInput = stdin.readLineSync()?.toLowerCase() ?? 'n';
  final enabled = enabledInput == 'y' || enabledInput == 's';

  stdout.write('Domain: ');
  final domain = stdin.readLineSync() ?? '';

  stdout.write('Description: ');
  final description = stdin.readLineSync() ?? '';

  // Optional fields (enterprise)
  print('\n📋 Optional fields (press Enter to skip):');

  stdout.write('Team: ');
  final team = stdin.readLineSync()?.trim();

  stdout.write('Activity: ');
  final activity = stdin.readLineSync()?.trim();

  stdout.write('Prototype: ');
  final prototype = stdin.readLineSync()?.trim();

  stdout.write('Minimum version: ');
  final minVersion = stdin.readLineSync()?.trim();

  stdout.write('Maximum version: ');
  final maxVersion = stdin.readLineSync()?.trim();

  // Create unified entity
  final toggle = EnhancedFeatureToggleEntity(
    name: name,
    enabled: enabled,
    domain: domain,
    description: description,
    team: team?.isEmpty == true ? null : team,
    activity: activity?.isEmpty == true ? null : activity,
    prototype: prototype?.isEmpty == true ? null : prototype,
    minVersion: minVersion?.isEmpty == true ? null : minVersion,
    maxVersion: maxVersion?.isEmpty == true ? null : maxVersion,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Save to enhanced database
  final db = EnhancedFeatureToggleDatabase(Directory.current.path);
  await db.insertFeatureToggle(toggle);

  // Export to YAML (using existing system if available)
  try {
    // Try to use existing exporter (may need adaptation)
    print('💾 Saving to database...');
    print('✅ Feature toggle "$name" added successfully!');

    if (team != null || activity != null || prototype != null) {
      print('📊 Enterprise fields added: ${[
        team,
        activity,
        prototype
      ].where((e) => e?.isNotEmpty == true).join(', ')}');
    }
  } catch (e) {
    print('⚠️  Feature toggle saved, but export error: $e');
  }
}
