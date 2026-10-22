import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../../data/models/microfrontend_project_model.dart';

/// Service to locate and read `.shepherd/microfrontends.yaml` across directories.
class MicrofrontendsManifestService {
  /// Checks whether a manifest file contains any microfrontends defined.
  static bool hasMicrofrontends(File file) {
    try {
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return false;
      final doc = loadYaml(content);
      if (doc is YamlMap && doc['microfrontends'] is YamlList) {
        return (doc['microfrontends'] as YamlList).isNotEmpty;
      }
    } catch (_) {}
    return false;
  }

  /// Finds `.shepherd/microfrontends.yaml` starting at [startDir] and walking up parents.
  /// If a candidate file has an empty list of microfrontends (e.g. placeholder),
  /// it keeps searching up the parent chain for a populated manifest before falling back.
  static File? findManifestFile([Directory? startDir]) {
    var current = startDir ?? Directory.current;
    File? firstFound;
    while (true) {
      final candidate =
          File(p.join(current.path, '.shepherd', 'microfrontends.yaml'));
      if (candidate.existsSync()) {
        firstFound ??= candidate;
        if (hasMicrofrontends(candidate)) return candidate;
      }

      final legacy = File(
          p.join(current.path, 'dev_tools', 'shepherd', 'microfrontends.yaml'));
      if (legacy.existsSync()) {
        firstFound ??= legacy;
        if (hasMicrofrontends(legacy)) return legacy;
      }

      final parent = current.parent;
      if (parent.path == current.path) break;
      current = parent;
    }
    return firstFound;
  }

  /// Loads microfrontends list along with the root project Directory.
  static List<MicrofrontendProjectModel> load([Directory? startDir]) {
    final file = findManifestFile(startDir);
    if (file == null) return const [];
    try {
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return const [];
      final doc = loadYaml(content);
      if (doc is YamlMap && doc['microfrontends'] is YamlList) {
        return (doc['microfrontends'] as YamlList)
            .whereType<YamlMap>()
            .map((e) => MicrofrontendProjectModel.fromMap(
                Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Returns the base directory where `.shepherd/microfrontends.yaml` resides (the container project).
  static Directory? baseDirectory([Directory? startDir]) {
    final file = findManifestFile(startDir);
    if (file == null) return null;
    final parent = file.parent;
    if (parent.path.endsWith('.shepherd')) {
      return parent.parent;
    } else if (parent.path.endsWith('shepherd') &&
        parent.parent.path.endsWith('dev_tools')) {
      return parent.parent.parent;
    }
    return parent.parent;
  }
}
