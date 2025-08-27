import 'dart:io';
import 'package:shepherd/src/sync/domain/services/path_validator_service.dart';

/// Command for validate and create essential patchs for Shepherd CLI.
/// Can be called at the beginning of any command flow.
Future<void> validatePathsCommand(List<String> requiredPaths, {String? baseDir}) async {
  final root = baseDir ?? Directory.current.path;
  final yamlFiles = [
    '.shepherd/domains.yaml',
    '.shepherd/config.yaml',
    '.shepherd/feature_toggles.yaml',
    '.shepherd/environments.yaml',
    '.shepherd/project.yaml',
    '.shepherd/sync_config.yaml',
    '.shepherd/user_active.yaml',
  ];
  final dbFile = '.shepherd/shepherd.db';

  final foundYaml = <String>[];
  final createdYaml = <String>[];
  final missingYaml = <String>[];

  // First, check and report missing files
  for (final path in yamlFiles) {
    final fullPath = path.startsWith('/') ? path : Directory(root).uri.resolve(path).toFilePath();
    final exists = File(fullPath).existsSync();
    if (exists) {
      foundYaml.add(fullPath);
    } else {
      missingYaml.add(fullPath);
    }

    if (missingYaml.isNotEmpty) {
      print('Missing YAML files (will be created automatically):');
      for (var m in missingYaml) {
        print('  ✗ $m');
      }
    }

    // Create files if not exist
    for (final fullPath in missingYaml) {
      File(fullPath).createSync(recursive: true);
      File(fullPath).writeAsStringSync('');
      createdYaml.add(fullPath);
    }

    final dbFullPath = Directory(root).uri.resolve(dbFile).toFilePath();
    final dbExists = File(dbFullPath).existsSync();
    var dbCreated = false;
    if (!dbExists) {
      File(dbFullPath).createSync(recursive: true);
      dbCreated = true;
    }

    print('YAML files in .shepherd:');
    if (foundYaml.isNotEmpty) {
      for (var f in foundYaml) {
        print('  ✔ $f');
      }
    } else {
      print('  No YAML files found.');
    }
    if (createdYaml.isNotEmpty) {
      print('Created YAML files:');
      for (var c in createdYaml) {
        print('  ✚ $c');
      }
    }

    print('Database in .shepherd:');
    if (dbExists) {
      print('  ✔ $dbFullPath');
    } else if (dbCreated) {
      print('  ✚ $dbFullPath (automatically created)');
    } else {
      print('  shepherd.db not found.');
    }

    if (foundYaml.isEmpty && createdYaml.isEmpty) {
      print('No YAML files found or created.');
    }
    if (!dbExists && !dbCreated) {
      print('shepherd.db not found or created.');
    }

    // Use PathValidatorService to validate all paths
    final errors = PathValidatorService.validatePaths([...yamlFiles, dbFile], baseDir: root);

    if (errors.isNotEmpty) {
      print('[Shepherd][ERROR] Paths not found:');
      errors.forEach(print);
      print('Please fix the paths above before continuing.');
      exit(1);
    }
  }
}
