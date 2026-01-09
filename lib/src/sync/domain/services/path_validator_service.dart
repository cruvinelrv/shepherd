import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shepherd/src/sync/presentation/cli/sync_controller.dart';

/// Validates all file and directory paths used by Shepherd CLI.
/// Returns a list of errors found or an empty list if everything is correct.
class PathValidatorService {
  /// Receives a list of relative or absolute paths and validates if they exist.
  /// [baseDir] is the root directory of the project.
  static List<String> validatePaths(List<String> paths, {String? baseDir}) {
    final errors = <String>[];
    final root = baseDir ?? Directory.current.path;
    for (final path in paths) {
      final fullPath =
          p.normalize(p.isAbsolute(path) ? path : p.join(root, path));
      final exists =
          File(fullPath).existsSync() || Directory(fullPath).existsSync();
      if (!exists) {
        errors.add('Path not found: $fullPath');
      }
    }
    return errors;
  }

  /// Validates essential Shepherd files and initializes project if needed.
  /// Returns true if everything is ok, false if it failed.
  static Future<bool> validateAndInitProjectIfNeeded(
      List<String> essentialFiles,
      Map<String, Future<void> Function(List<String>)> registry) async {
    final missingOrInvalidFiles = essentialFiles.where((f) {
      final file = File(f);
      if (!file.existsSync()) return true;
      if (f.endsWith('project.yaml') && file.lengthSync() == 0) return true;
      if (f.endsWith('.yaml') && file.lengthSync() == 0) return true;
      return false;
    }).toList();

    // If only user_active.yaml is missing, register the active user
    if (missingOrInvalidFiles.length == 1 &&
        missingOrInvalidFiles.first.contains('user_active.yaml')) {
      stderr.writeln(
          '\x1B[33mMissing active user file. Registering active user...\x1B[0m');
      // Directly call the internal method
      await SyncController().ensureActiveUser();
      // After registration, revalidate
      final stillMissing = essentialFiles.where((f) {
        final file = File(f);
        if (!file.existsSync()) return true;
        if (f.endsWith('project.yaml') && file.lengthSync() == 0) return true;
        if (f.endsWith('.yaml') && file.lengthSync() == 0) return true;
        return false;
      }).toList();
      if (stillMissing.isNotEmpty) {
        stderr.writeln('\x1B[31mFailed to register active user file!\x1B[0m');
        for (final f in stillMissing) {
          stderr.writeln('- $f');
        }
        return false;
      }
      return true;
    }

    // If more than one essential file is missing, ask user what to do
    if (missingOrInvalidFiles.isNotEmpty) {
      stderr.writeln('\x1B[31mMissing or invalid essential files:\x1B[0m');
      for (final f in missingOrInvalidFiles) {
        stderr.writeln('- $f');
      }
      stderr.writeln('\n\x1B[33mWhat would you like to do?\x1B[0m');
      stderr.writeln(
          '[1] Initialize a new project (\x1B[36mshepherd init\x1B[0m)');
      stderr.writeln(
          '[2] Pull configuration from an existing project (\x1B[36mshepherd pull\x1B[0m)');
      stderr.writeln('[3] Exit');
      stderr.write('\nChoose an option [1-3]: ');

      final choice = stdin.readLineSync()?.trim();

      if (choice == '1') {
        stderr.writeln('Running \x1B[36mshepherd init\x1B[0m...');
        final handler = registry['init'];
        if (handler != null) {
          await handler([]);
          // After init, revalidate essential files
          final stillMissing = essentialFiles.where((f) {
            final file = File(f);
            if (!file.existsSync()) return true;
            if (f.endsWith('project.yaml') && file.lengthSync() == 0)
              return true;
            if (f.endsWith('.yaml') && file.lengthSync() == 0) return true;
            return false;
          }).toList();
          if (stillMissing.isNotEmpty) {
            stderr.writeln(
                '\x1B[31mFailed to initialize all essential files!\x1B[0m');
            for (final f in stillMissing) {
              stderr.writeln('- $f');
            }
            return false;
          }
        } else {
          stderr.writeln('Init command not found in registry.');
          return false;
        }
      } else if (choice == '2') {
        stderr.writeln('Running \x1B[36mshepherd pull\x1B[0m...');
        final handler = registry['pull'];
        if (handler != null) {
          await handler([]);
          return true;
        } else {
          stderr.writeln('Pull command not found in registry.');
          return false;
        }
      } else {
        stderr.writeln('Exiting...');
        return false;
      }
    }
    return true;
  }
}
