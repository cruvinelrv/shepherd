import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The login `shepherd login` saved for this folder (`.shepherd/session.yaml`).
class LoginSession {
  final String token;
  final String environment;
  final String? corporationId;
  final String? personId;
  final String? projectId;

  const LoginSession(
      {required this.token,
      required this.environment,
      this.corporationId,
      this.personId,
      this.projectId});

  /// What the engine's `initialize` takes as `auth`.
  Map<String, dynamic> toAuth() => {
        'token': token,
        'environment': environment,
        if (corporationId != null) 'corporationId': corporationId,
        if (personId != null) 'personId': personId,
        if (projectId != null) 'projectId': projectId,
      };

  /// Null when nobody is logged in here.
  static LoginSession? read([Directory? root]) {
    final dir = root ?? Directory.current;
    final file = File(p.join(dir.path, '.shepherd', 'session.yaml'));
    if (!file.existsSync()) return null;
    try {
      final doc = loadYaml(file.readAsStringSync());
      if (doc is! YamlMap) return null;
      final token = doc['token']?.toString() ?? '';
      if (token.isEmpty) return null;
      String? opt(String k) {
        final v = doc[k]?.toString();
        return v == null || v.isEmpty ? null : v;
      }

      // The project this folder is linked to lives in config.yaml (`shepherd login`).
      String? projectId;
      final cfg = File(p.join(dir.path, '.shepherd', 'config.yaml'));
      if (cfg.existsSync()) {
        final c = loadYaml(cfg.readAsStringSync());
        if (c is YamlMap && c['project_id'] != null)
          projectId = c['project_id'].toString();
      }

      return LoginSession(
        token: token,
        environment: doc['env']?.toString() == 'uat' ? 'uat' : 'prod',
        corporationId: opt('corporationId'),
        personId: opt('personId') ?? opt('userId'),
        projectId: projectId,
      );
    } catch (_) {
      return null;
    }
  }
}
