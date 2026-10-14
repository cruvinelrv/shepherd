import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// The login `shepherd login` saved: one for the whole computer
/// (`~/.shepherd/session.yaml`), or, from older versions, one in a folder's
/// `.shepherd/session.yaml`, which is looked at first.
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
  static LoginSession? read([Directory? root, Directory? home]) {
    final dir = root ?? Directory.current;
    return _readFile(
            File(p.join(dir.path, '.shepherd', 'session.yaml')), dir) ??
        _readFile(globalFile(home: home), dir);
  }

  /// `~/.shepherd/session.yaml`: the login that works in every folder.
  static File globalFile({Directory? home}) {
    final h = home?.path ??
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return File(p.join(h, '.shepherd', 'session.yaml'));
  }

  /// Saves the login for the whole computer (readable only by the user). A
  /// folder that still has a login of its own gets the same one, so the two
  /// never disagree.
  static void saveGlobal(
      {required String token,
      required String environment,
      String? corporationId,
      Directory? home,
      Directory? folder}) {
    final global = globalFile(home: home);
    final doc = <String, dynamic>{};
    try {
      final old =
          global.existsSync() ? loadYaml(global.readAsStringSync()) : null;
      if (old is YamlMap) doc.addAll(Map<String, dynamic>.from(old));
    } catch (_) {}
    doc['token'] = token;
    doc['env'] = environment;
    if (corporationId != null) doc['corporationId'] = corporationId;
    final text = YamlWriter().write(doc);
    global.parent.createSync(recursive: true);
    global.writeAsStringSync(text);
    if (!Platform.isWindows) {
      try {
        Process.runSync('chmod', ['600', global.path]);
      } catch (_) {}
    }
    final local = File(p.join(
        (folder ?? Directory.current).path, '.shepherd', 'session.yaml'));
    if (local.existsSync()) local.writeAsStringSync(text);
  }

  static LoginSession? _readFile(File file, Directory dir) {
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
