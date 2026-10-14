import 'dart:io';
import 'package:yaml/yaml.dart';
import '../../../ai_client/session_reader.dart';
import '../../domain/entities/shell_session_entity.dart';
import '../../domain/services/ai_config_service.dart';
import '../../domain/services/workspace_manifest_service.dart';

/// Model representing the shell session, responsible for loading
/// workspace configuration, user info, and session tokens.
class ShellSessionModel extends ShellSessionEntity {
  const ShellSessionModel({
    required super.projectName,
    super.workspaceName,
    super.userName,
    super.userEmail,
    super.environment,
    super.aiProvider,
    super.aiModel,
    super.isAuthenticated,
  });

  /// Factory to instantiate [ShellSessionModel] by inspecting the current working directory
  /// and local `.shepherd` configuration files.
  factory ShellSessionModel.loadFromWorkspace() {
    // 1. Resolve project name: only what the project files say, never the folder's name
    var projectName = '';
    final projectFile = File('.shepherd/project.yaml');
    if (projectFile.existsSync()) {
      try {
        final content = projectFile.readAsStringSync();
        final yaml = loadYaml(content);
        if (yaml is Map && yaml['project_name'] != null) {
          projectName = yaml['project_name'].toString();
        } else if (yaml is Map && yaml['name'] != null) {
          projectName = yaml['name'].toString();
        }
      } catch (_) {}
    } else {
      final configFile = File('.shepherd/config.yaml');
      if (configFile.existsSync()) {
        try {
          final content = configFile.readAsStringSync();
          final yaml = loadYaml(content);
          if (yaml is Map && yaml['project_id'] != null) {
            projectName = yaml['project_id'].toString();
          }
        } catch (_) {}
      }
    }

    // 2. Resolve workspace name (from current or parent workspace.yaml; null when there is none)
    String? workspaceName;
    final manifest = WorkspaceManifest.tryLoad(Directory.current);
    if (manifest != null) {
      workspaceName = manifest.name;
    }

    // 3. Resolve active user
    String? userName;
    String? userEmail;
    final userActiveFile = File('.shepherd/user_active.yaml');
    if (userActiveFile.existsSync()) {
      try {
        final content = userActiveFile.readAsStringSync();
        final yaml = loadYaml(content);
        if (yaml is YamlMap) {
          final first = yaml['first_name']?.toString() ?? '';
          final last = yaml['last_name']?.toString() ?? '';
          final full = '$first $last'.trim();
          if (full.isNotEmpty) userName = full;
          userEmail = yaml['email']?.toString();
        }
      } catch (_) {}
    }

    // 4. Resolve session & auth state
    final login = LoginSession.read();
    final isAuthenticated = login != null;
    final env = login?.environment;

    // 5. Resolve AI configuration
    String? aiProvider;
    String? aiModel;
    try {
      final aiConfig = AiConfigService().load();
      if (aiConfig != null) {
        final isLocal = aiConfig.activeProvider == 'ollama' ||
            aiConfig.activeProvider == 'local_ai' ||
            aiConfig.activeProvider == 'lan_ai' ||
            (aiConfig.baseUrl != null && aiConfig.baseUrl!.isNotEmpty);
        if (aiConfig.apiKey.isNotEmpty || isLocal) {
          aiProvider = aiConfig.provider;
          aiModel = aiConfig.model;
        }
      }
    } catch (_) {}

    return ShellSessionModel(
      projectName: projectName,
      workspaceName: workspaceName,
      userName: userName,
      userEmail: userEmail,
      environment: env,
      aiProvider: aiProvider,
      aiModel: aiModel,
      isAuthenticated: isAuthenticated,
    );
  }
}
