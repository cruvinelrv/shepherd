import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// Datasource for managing update check cache
class UpdateCacheDatasource {
  static const String _cacheFileName = 'update_cache.yaml';

  final String _projectPath;

  UpdateCacheDatasource(this._projectPath);

  /// Get the cache file path
  String get _cachePath => '$_projectPath/.shepherd/$_cacheFileName';

  /// Read the last check timestamp from cache
  Future<DateTime?> getLastCheckTime() async {
    try {
      final file = File(_cachePath);
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final yaml = loadYaml(content) as Map?;

      if (yaml == null || yaml['last_check'] == null) {
        return null;
      }

      return DateTime.tryParse(yaml['last_check'] as String);
    } catch (e) {
      // If cache is corrupted or missing, treat as no cache
      return null;
    }
  }

  /// Save the check timestamp to cache
  Future<void> saveLastCheckTime(DateTime time) async {
    try {
      // Ensure .shepherd directory exists
      final shepherdDir = Directory('$_projectPath/.shepherd');
      if (!await shepherdDir.exists()) {
        await shepherdDir.create(recursive: true);
      }

      final file = File(_cachePath);
      final writer = YamlWriter();
      final yaml = writer.write({
        'last_check': time.toIso8601String(),
      });

      await file.writeAsString(yaml);
    } catch (e) {
      // Silent fail - cache is not critical
    }
  }
}
