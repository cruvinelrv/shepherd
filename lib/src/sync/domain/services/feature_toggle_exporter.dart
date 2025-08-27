import 'dart:io';
import 'package:yaml_writer/yaml_writer.dart';
import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';

Future<void> exportFeatureTogglesToYaml(
    FeatureToggleDatabase db, String projectPath) async {
  final toggles = await db.getAllFeatureToggles();
  final yamlList = toggles
      .map((t) => {
            'name': t.name,
            'enabled': t.enabled,
            'domain': t.domain,
            'description': t.description,
          })
      .toList();
  final writer = YamlWriter();
  final yamlContent = writer.write(yamlList);
  final exportDir = Directory('$projectPath/.shepherd');
  if (!exportDir.existsSync()) {
    exportDir.createSync(recursive: true);
  }
  final file = File('${exportDir.path}/feature_toggles.yaml');
  await file.writeAsString(yamlContent);
}
