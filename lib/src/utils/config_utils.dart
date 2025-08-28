import 'dart:io';
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

ConfigDatabase openConfigDb() {
  // Always use .shepherd/shepherd.db in the project root
  return ConfigDatabase('${Directory.current.path}/.shepherd/shepherd.db');
}
