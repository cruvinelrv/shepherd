import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';
import 'package:shepherd/src/domains/data/datasources/local/enhanced_feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/enhanced_feature_toggle_entity.dart';
import 'package:shepherd/src/menu/presentation/cli/input_utils.dart';

Future<void> runListFeatureTogglesCommand() async {
  print('📋 Listando Feature Toggles\n');

  // Try to load from enhanced system first
  final enhancedDb = EnhancedFeatureToggleDatabase(Directory.current.path);
  final enhancedToggles = await enhancedDb.getAllFeatureToggles();

  // Also load from basic system for migration
  final basicDb = FeatureToggleDatabase(Directory.current.path);
  List<dynamic> basicToggles = [];
  try {
    basicToggles = await basicDb.getAllFeatureToggles();
  } catch (e) {
    // Basic system may not exist, that's fine
  }

  // Display statistics
  print('📊 Statistics:');
  print('   Enhanced System: ${enhancedToggles.length} feature toggles');
  print('   Basic System: ${basicToggles.length} feature toggles');

  if (enhancedToggles.isEmpty && basicToggles.isEmpty) {
    print('\n❌ No feature toggles found.');
    print('💡 Use the "Add Feature Toggle" command to create the first one.');
    pauseForEnter();
    return;
  }

  // Show visualization options
  print('\nListing options:');
  print('1. All feature toggles (enhanced)');
  print('2. By domain');
  print('3. By team');
  print('4. Only enabled');
  print('5. Only disabled');
  if (basicToggles.isNotEmpty) {
    print('6. Basic system feature toggles (for migration)');
  }

  stdout.write('\nChoose an option (1-${basicToggles.isNotEmpty ? 6 : 5}): ');
  final option = stdin.readLineSync()?.trim() ?? '1';

  switch (option) {
    case '1':
      _displayEnhancedToggles(enhancedToggles, 'All Feature Toggles');
      break;

    case '2':
      stdout.write('Enter domain: ');
      final domain = stdin.readLineSync()?.trim() ?? '';
      final filtered = enhancedToggles
          .where((t) => t.domain.toLowerCase().contains(domain.toLowerCase()))
          .toList();
      _displayEnhancedToggles(filtered, 'Feature Toggles - Domain: $domain');
      break;

    case '3':
      stdout.write('Enter team: ');
      final team = stdin.readLineSync()?.trim() ?? '';
      final filtered = enhancedToggles
          .where((t) => t.team?.toLowerCase().contains(team.toLowerCase()) == true)
          .toList();
      _displayEnhancedToggles(filtered, 'Feature Toggles - Team: $team');
      break;

    case '4':
      final enabled = enhancedToggles.where((t) => t.enabled).toList();
      _displayEnhancedToggles(enabled, 'Enabled Feature Toggles');
      break;

    case '5':
      final disabled = enhancedToggles.where((t) => !t.enabled).toList();
      _displayEnhancedToggles(disabled, 'Disabled Feature Toggles');
      break;

    case '6':
      if (basicToggles.isNotEmpty) {
        _displayBasicToggles(basicToggles);
        print('\n💡 To migrate this data to the enhanced system, use the migration option.');
      }
      break;

    default:
      print('Invalid option.');
  }

  pauseForEnter();
}

void _displayEnhancedToggles(List<EnhancedFeatureToggleEntity> toggles, String title) {
  print('\n🎯 $title:');

  if (toggles.isEmpty) {
    print('   No feature toggles found with the specified criteria.');
    return;
  }

  for (final toggle in toggles) {
    final status = toggle.enabled ? '✅' : '❌';
    print('\n$status [${toggle.id}] ${toggle.name}');
    print('   Domain: ${toggle.domain}');
    print('   Status: ${toggle.enabled ? 'Enabled' : 'Disabled'}');
    print('   Description: ${toggle.description}');

    // Enterprise fields (if filled)
    if (toggle.team != null) print('   Team: ${toggle.team}');
    if (toggle.activity != null) print('   Activity: ${toggle.activity}');
    if (toggle.prototype != null) print('   Prototype: ${toggle.prototype}');
    if (toggle.minVersion != null) {
      print('   Min Version: ${toggle.minVersion}');
    }
    if (toggle.maxVersion != null) {
      print('   Max Version: ${toggle.maxVersion}');
    }
    if (toggle.createdAt != null) {
      print('   Created: ${toggle.createdAt!.toLocal().toString().split('.')[0]}');
    }
  }
}

void _displayBasicToggles(List<dynamic> toggles) {
  print('\n⚠️  Basic System Feature Toggles (Migration Required):');

  for (final toggle in toggles) {
    final status = toggle.enabled ? '✅' : '❌';
    print('\n$status [${toggle.id}] ${toggle.name}');
    print('   Domain: ${toggle.domain}');
    print('   Status: ${toggle.enabled ? 'Enabled' : 'Disabled'}');
    print('   Description: ${toggle.description}');
  }
}
