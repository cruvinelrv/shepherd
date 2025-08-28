import 'dart:io';
import 'package:path/path.dart' as p;

/// Validates all file and directory paths used by Shepherd CLI.
/// Returns a list of errors found or an empty list if everything is correct.
class PathValidatorService {
  /// Receives a list of relative or absolute paths and validates if they exist.
  /// [baseDir] is the root directory of the project.
  static List<String> validatePaths(List<String> paths, {String? baseDir}) {
    final errors = <String>[];
    final root = baseDir ?? Directory.current.path;
    for (final path in paths) {
      final fullPath = p.normalize(p.isAbsolute(path) ? path : p.join(root, path));
      final exists = File(fullPath).existsSync() || Directory(fullPath).existsSync();
      if (!exists) {
        errors.add('Path not found: $fullPath');
      }
    }
    return errors;
  }

  /// Validates essential Shepherd files and initializes project if needed.
  /// Returns true if everything is ok, false if it failed.
  static Future<bool> validateAndInitProjectIfNeeded(List<String> essentialFiles,
      Map<String, Future<void> Function(List<String>)> registry) async {
    final missingOrInvalidFiles = essentialFiles.where((f) {
      final file = File(f);
      if (!file.existsSync()) return true;
      if (f.endsWith('project.yaml') && file.lengthSync() == 0) return true;
      if (f.endsWith('.yaml') && file.lengthSync() == 0) return true;
      return false;
    }).toList();
    if (missingOrInvalidFiles.isNotEmpty) {
      stderr.writeln('\x1B[31mMissing or invalid essential files:\x1B[0m');
      for (final f in missingOrInvalidFiles) {
        stderr.writeln('- $f');
      }
      stderr.writeln('Running \x1B[36mshepherd init\x1B[0m to initialize the project...');
      final handler = registry['init'];
      if (handler != null) {
        await handler([]);
        // After init, revalidate essential files
        final stillMissing = essentialFiles.where((f) {
          final file = File(f);
          if (!file.existsSync()) return true;
          if (f.endsWith('project.yaml') && file.lengthSync() == 0) return true;
          if (f.endsWith('.yaml') && file.lengthSync() == 0) return true;
          return false;
        }).toList();
        if (stillMissing.isNotEmpty) {
          stderr.writeln('\x1B[31mFailed to initialize all essential files!\x1B[0m');
          for (final f in stillMissing) {
            stderr.writeln('- $f');
          }
          return false;
        }
      } else {
        stderr.writeln('Init command not found in registry.');
        return false;
      }
    }
    return true;
  }
}
