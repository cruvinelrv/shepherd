import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import '../../domain/entities/update_entities.dart';

/// Datasource for managing update configuration
class UpdateConfigDatasource {
  static const String _configFileName = 'config.yaml';

  final String _projectPath;

  UpdateConfigDatasource(this._projectPath);

  /// Get the config file path
  String get _configPath => '$_projectPath/.shepherd/$_configFileName';

  /// Read update configuration from config.yaml
  Future<UpdateConfig> getUpdateConfig() async {
    try {
      final file = File(_configPath);
      if (!await file.exists()) {
        // No config file, return default
        return UpdateConfig.defaultConfig();
      }

      final content = await file.readAsString();
      final yaml = loadYaml(content) as Map?;

      return UpdateConfig.fromYaml(yaml as Map<String, dynamic>?);
    } catch (e) {
      // If config is corrupted or missing, return default
      return UpdateConfig.defaultConfig();
    }
  }

  /// Save update configuration to config.yaml
  /// Merges with existing configuration to preserve other settings
  Future<void> saveUpdateConfig(UpdateConfig config) async {
    try {
      // Ensure .shepherd directory exists
      final shepherdDir = Directory('$_projectPath/.shepherd');
      if (!await shepherdDir.exists()) {
        await shepherdDir.create(recursive: true);
      }

      final file = File(_configPath);
      Map<String, dynamic> existingConfig = {};

      // Read existing configuration if file exists
      if (await file.exists()) {
        final content = await file.readAsString();
        final yaml = loadYaml(content);
        if (yaml is Map) {
          existingConfig = Map<String, dynamic>.from(yaml);
        }
      }

      // Merge auto_update configuration
      existingConfig['auto_update'] = config.toYaml();

      // Write merged configuration
      final writer = YamlWriter();
      final yamlContent = writer.write(existingConfig);
      await file.writeAsString(yamlContent);
    } catch (e) {
      // Silent fail - config is not critical
    }
  }
}
