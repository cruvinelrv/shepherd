import 'dart:io';
import 'package:path/path.dart' as p;

/// Validates all file and directory paths used by Shepherd CLI.
/// Retorna uma lista de erros encontrados ou uma lista vazia se tudo estiver correto.
class PathValidatorService {
  /// Recebe uma lista de caminhos relativos ou absolutos e valida se existem.
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
}
