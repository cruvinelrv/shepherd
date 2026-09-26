import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../utils/shepherd_dir_gitignore.dart';

/// Service responsible for ensuring the standard Shepherd Platform workspace and project
/// YAML files exist upon opening the CLI/Shell, creating them if missing.
class WorkspaceScaffoldService {
  /// Ensures all canonical workspace and project YAML files exist in `.shepherd/`.
  /// Returns the list of newly created file paths.
  static List<String> ensureShepherdFiles({String? basePath}) {
    final root = basePath ?? Directory.current.path;
    final shepherdDir = Directory(p.join(root, '.shepherd'));
    if (!shepherdDir.existsSync()) {
      shepherdDir.createSync(recursive: true);
    }

    final folderName = p.basename(root);
    final createdFiles = <String>[];

    // Ensure .shepherd/.gitignore protects secrets
    ensureShepherdGitignoreEntries([
      'session.yaml',
      'ai_config.yaml',
      'shepherd.db',
      'update_cache.yaml',
      'environment_variables.yaml',
    ], basePath: root);

    // 1. Workspace-level YAML definitions
    final workspaceDefinitions = <String, String>{
      '.shepherd/workspace.yaml': '''workspace:
  name: "$folderName"
  version: "1.0.0"
  team_members: []
  squads: []
  projects: {}
''',
      '.shepherd/skills.yaml': '''# Shepherd Workspace Skills
skills: []
''',
      '.shepherd/domains.yaml': '''domains: []
''',
      '.shepherd/sync_config.yaml': '''# Shepherd Sync Config
files:
  - path: .shepherd/workspace.yaml
    required: true
  - path: .shepherd/skills.yaml
    required: false
  - path: .shepherd/project.yaml
    required: true
  - path: .shepherd/specs.yaml
    required: false
  - path: .shepherd/domains.yaml
    required: true
  - path: .shepherd/environments.yaml
    required: true
  - path: .shepherd/feature_toggles.yaml
    required: true
  - path: .shepherd/config.yaml
    required: true
''',
    };

    // 2. Project-level YAML definitions
    final projectDefinitions = <String, String>{
      '.shepherd/project.yaml': '''name: "$folderName"
init_mode: "standard"
''',
      '.shepherd/specs.yaml': '''# Shepherd Project Specifications
specs:
  project: "$folderName"
  version: "1.0.0"
  architecture: "DDD"
  requirements: []
''',
      '.shepherd/environments.yaml': '''environments: []
''',
      '.shepherd/feature_toggles.yaml': '''[]
''',
      '.shepherd/config.yaml': '''project_id: "$folderName"
''',
      '.shepherd/microfrontends.yaml': '''microfrontends: []
''',
      '.shepherd/shepherd_activity.yaml': '''stories: []
''',
    };

    final allDefinitions = {
      ...workspaceDefinitions,
      ...projectDefinitions,
    };

    for (final entry in allDefinitions.entries) {
      final file = File(p.join(root, entry.key));
      if (!file.existsSync() || file.lengthSync() == 0) {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(entry.value);
        createdFiles.add(entry.key);
      }
    }

    return createdFiles;
  }
}
