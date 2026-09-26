import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import '../../domain/entities/shell_session_entity.dart';
import '../../domain/services/ai_config_service.dart';

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
    // 1. Resolve project name
    var projectName = p.basename(Directory.current.path);
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

    // 2. Resolve workspace name
    String? workspaceName;
    final workspaceFile = File('.shepherd/workspace.yaml');
    if (workspaceFile.existsSync()) {
      try {
        final content = workspaceFile.readAsStringSync();
        final yaml = loadYaml(content);
        if (yaml is Map && yaml['workspace'] is Map) {
          workspaceName = yaml['workspace']['name']?.toString();
        }
      } catch (_) {}
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
    String? env;
    bool isAuthenticated = false;
    final sessionFile = File('.shepherd/session.yaml');
    if (sessionFile.existsSync()) {
      try {
        final content = sessionFile.readAsStringSync();
        final yaml = loadYaml(content);
        if (yaml is YamlMap) {
          final token = yaml['token']?.toString();
          if (token != null && token.isNotEmpty) {
            isAuthenticated = true;
          }
          env = yaml['env']?.toString();
        }
      } catch (_) {}
    }

    // 5. Resolve AI configuration
    String? aiProvider;
    String? aiModel;
    try {
      final aiConfig = AiConfigService().load();
      if (aiConfig != null && aiConfig.apiKey.isNotEmpty) {
        aiProvider = aiConfig.provider;
        aiModel = aiConfig.model;
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
