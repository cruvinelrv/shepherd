import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/config/data/datasources/local/config_database.dart';

/// Reads the debug flag from .shepherd/config.yaml
bool isDebugModeEnabled() {
  final configFile = File('.shepherd/config.yaml');
  if (!configFile.existsSync()) return false;
  final lines = configFile.readAsLinesSync();
  for (final line in lines) {
    if (line.trim().startsWith('debug:')) {
      final value = line.split(':')[1].trim();
      return value.toLowerCase() == 'true';
    }
  }
  return false;
}


/// Reads the configured repository type from .shepherd/config.yaml ('github' or 'azure').
String? getRepoType({String? projectPath}) {
  final basePath = projectPath ?? Directory.current.path;
  final configFile = File('$basePath/.shepherd/config.yaml');
  if (!configFile.existsSync()) return null;
  try {
    final content = configFile.readAsStringSync();
    final config = loadYaml(content);
    if (config is Map && config['repoType'] != null) {
      final val = config['repoType'].toString().trim().toLowerCase();
      if (val == 'github' || val == 'azure') return val;
    }
  } catch (_) {}
  return null;
}

/// Reads the pullRequestEnabled flag from .shepherd/config.yaml (defaults to true).
bool isPullRequestEnabled({String? projectPath}) {
  final basePath = projectPath ?? Directory.current.path;
  final configFile = File('$basePath/.shepherd/config.yaml');
  if (!configFile.existsSync()) return true;
  try {
    final content = configFile.readAsStringSync();
    final config = loadYaml(content);
    if (config is Map && config.containsKey('pullRequestEnabled')) {
      return config['pullRequestEnabled'] == true;
    }
  } catch (_) {}
  return true;
}

ConfigDatabase openConfigDb() {
  // Always use .shepherd/shepherd.db in the project root
  return ConfigDatabase('${Directory.current.path}/.shepherd/shepherd.db');
}

