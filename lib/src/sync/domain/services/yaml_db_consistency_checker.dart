import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';
import 'package:yaml/yaml.dart' as yaml_pkg;
import 'package:path/path.dart' as p;

/// Checks if the content of shepherd.db is consistent with the YAML files.
/// Returns true if consistent, false if not.
Future<bool> checkYamlDbConsistency(String projectPath) async {
  final syncConfigFile =
      File(p.join(projectPath, 'dev_tools/shepherd/sync_config.yaml'));
  if (!syncConfigFile.existsSync()) {
    print('sync_config.yaml not found.');
    return false;
  }
  final configContent = syncConfigFile.readAsStringSync();
  final configYaml = yaml_pkg.loadYaml(configContent);
  final files = configYaml['files'] as List?;
  if (files == null) return false;
  for (final entry in files) {
    final path = entry['path']?.toString();
    final requiredSync = entry['required'] == true;
    if (path == null) continue;
    final file = File(p.join(projectPath, path));
    // Special case: feature_toggles.yaml missing and required: recreate from DB
    if (requiredSync && !file.existsSync()) {
      print('Inconsistency: required file missing -> $path');
      return false;
    }
    // Special case: feature_toggles.yaml content check
    if (path.endsWith('feature_toggles.yaml') && file.existsSync()) {
      final db = FeatureToggleDatabase(projectPath);
      final dbToggles = await db.getAllFeatureToggles();
      final yamlContent = file.readAsStringSync();
      final yamlList = yaml_pkg.loadYaml(yamlContent);
      if (yamlList is! List) {
        print('Inconsistency: $path is not a valid YAML list.');
        return false;
      }
      if (yamlList.length != dbToggles.length) {
        print(
            'Inconsistency: $path length (${yamlList.length}) != DB toggles (${dbToggles.length})');
        return false;
      }
      for (final y in yamlList) {
        final match = dbToggles.any((t) =>
            t.name == y['name'] &&
            t.enabled == y['enabled'] &&
            t.domain == y['domain'] &&
            t.description == y['description']);
        if (!match) {
          print('Inconsistency: toggle in $path not found in DB: ${y['name']}');
          return false;
        }
      }
    }
    // For other files, only existence is checked for now (can add content checks as needed)
  }
  return true;
}
