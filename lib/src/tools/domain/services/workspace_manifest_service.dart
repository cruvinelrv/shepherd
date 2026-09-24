import 'dart:io';
import 'package:yaml/yaml.dart';

/// One project entry in `.shepherd/workspace.yaml` — mirrors
/// shepherd_studio's WorkspaceProject (category/tech/tags/stack), minus the
/// strict enums: this side only reads the file, so a category or tech
/// string Studio adds later doesn't need a matching update here to still
/// show up correctly.
class WorkspaceProject {
  final String id;
  final String name;
  final String path;
  final String category;
  final String? techStack;
  final List<String> tags;
  final String? stack;

  const WorkspaceProject({
    required this.id,
    required this.name,
    required this.path,
    required this.category,
    this.techStack,
    this.tags = const [],
    this.stack,
  });

  static WorkspaceProject fromYamlMap(YamlMap map, String category) {
    final rawTags = map['tags'];
    final tags = rawTags is YamlList
        ? rawTags.map((e) => e.toString()).toList()
        : <String>[];

    final path = map['path']?.toString() ?? '';
    return WorkspaceProject(
      id: map['id']?.toString() ?? path,
      name: map['name']?.toString() ?? path,
      path: path,
      category: category,
      techStack: map['tech']?.toString(),
      tags: tags,
      stack: map['stack']?.toString(),
    );
  }
}

/// Read-only view of `.shepherd/workspace.yaml` — the multi-repo project
/// catalog Shepherd Studio generates when a developer configures a
/// workspace. Same file/shape Studio's WorkspaceManifest.tryParseFromDirectory
/// reads; this side never writes it.
class WorkspaceManifest {
  final String name;
  final String version;
  final List<WorkspaceProject> projects;

  const WorkspaceManifest({
    required this.name,
    required this.version,
    required this.projects,
  });

  static WorkspaceManifest? tryLoad() {
    final file = File('.shepherd/workspace.yaml');
    if (!file.existsSync()) return null;

    try {
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return null;

      final doc = loadYaml(content);
      if (doc is! YamlMap) return null;

      final wsMap = doc['workspace'];
      if (wsMap is! YamlMap) return null;

      final name = wsMap['name']?.toString() ?? 'Corporate Workspace';
      final version = wsMap['version']?.toString() ?? '1.0.0';

      final projects = <WorkspaceProject>[];
      final projectsMap = wsMap['projects'];
      if (projectsMap is YamlMap) {
        for (final entry in projectsMap.entries) {
          final category = entry.key.toString();
          final list = entry.value;
          if (list is YamlList) {
            for (final item in list) {
              if (item is YamlMap) {
                projects.add(WorkspaceProject.fromYamlMap(item, category));
              }
            }
          }
        }
      }

      return WorkspaceManifest(
          name: name, version: version, projects: projects);
    } catch (e) {
      return null;
    }
  }

  /// Short, LLM-friendly summary — one line per project, grouped by
  /// category — instead of dumping the raw (often deeply nested) YAML.
  String toSummary() {
    final buffer = StringBuffer();
    buffer.writeln(
        'Workspace: $name (v$version) — ${projects.length} projeto(s)');

    final byCategory = <String, List<WorkspaceProject>>{};
    for (final project in projects) {
      byCategory.putIfAbsent(project.category, () => []).add(project);
    }

    for (final category in byCategory.keys) {
      buffer.writeln('  [$category]');
      for (final project in byCategory[category]!) {
        final tech = project.techStack != null ? ' (${project.techStack})' : '';
        final tags =
            project.tags.isNotEmpty ? ' #${project.tags.join(' #')}' : '';
        buffer.writeln('    - ${project.name}$tech: ${project.path}$tags');
      }
    }

    return buffer.toString().trim();
  }
}
