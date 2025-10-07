import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/enhanced_feature_toggle_database.dart';

Future<void> runDeleteFeatureToggleCommand() async {
  print('🗑️ Excluindo Feature Toggle\n');

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
    if (toggle.description.isNotEmpty) {
      print('      ${toggle.description}');
    }
  }

  stdout.write('\nEnter the feature toggle ID to delete: ');
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

  // Show details and confirm deletion
  print('\n🔍 Feature Toggle to be deleted:');
  print('   ID: ${existingToggle.id}');
  print('   Name: ${existingToggle.name}');
  print('   Status: ${existingToggle.enabled ? 'Enabled' : 'Disabled'}');
  print('   Domain: ${existingToggle.domain}');
  print('   Description: ${existingToggle.description}');
  if (existingToggle.team != null) print('   Team: ${existingToggle.team}');
  if (existingToggle.activity != null) {
    print('   Activity: ${existingToggle.activity}');
  }

  stdout.write(
      '\n⚠️ Are you sure you want to delete this feature toggle? (y/N): ');
  final confirmation = stdin.readLineSync()?.toLowerCase().trim();

  if (confirmation != 'y' &&
      confirmation != 'yes' &&
      confirmation != 's' &&
      confirmation != 'sim') {
    print('❌ Operation cancelled.');
    return;
  }

  // Delete from database
  await db.deleteFeatureToggleById(id);

  print('\n✅ Feature toggle "${existingToggle.name}" deleted successfully!');
}
