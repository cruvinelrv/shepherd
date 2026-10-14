import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:yaml_writer/yaml_writer.dart';

import '../../../ai_client/session_reader.dart';

/// The workspace a company keeps in the Shepherd Union.
class UnionWorkspace {
  final String name;
  final String version;
  final int projectCount;

  const UnionWorkspace(
      {required this.name, required this.version, this.projectCount = 0});
}

/// Reads the company's workspace from the Union with the login `shepherd login`
/// saved, and writes it as `.shepherd/workspace.yaml` in a folder.
class UnionWorkspaceService {
  final http.Client _client;

  UnionWorkspaceService({http.Client? client})
      : _client = client ?? http.Client();

  static const _query = '''
    query { workspaceConfig { name version } projects { id } }
  ''';

  static Uri endpoint(String environment) => Uri.parse(environment == 'uat'
      ? 'https://union-uat.shepherdplatform.com/graphql'
      : 'https://union.shepherdplatform.com/graphql');

  /// The company's workspace, or null when the Union has none configured yet.
  /// Throws [UnionWorkspaceException] when the Union cannot be reached or says no.
  Future<UnionWorkspace?> fetch(LoginSession login) async {
    final http.Response r;
    try {
      r = await _client.post(
        endpoint(login.environment),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': login.token,
          if (login.corporationId != null)
            'X-Corporation-Id': login.corporationId!,
        },
        body: jsonEncode({'query': _query}),
      );
    } catch (e) {
      throw UnionWorkspaceException('$e');
    }
    if (r.statusCode != 200) {
      throw UnionWorkspaceException('HTTP ${r.statusCode}');
    }
    final body = jsonDecode(r.body);
    if (body is! Map) throw UnionWorkspaceException('unexpected answer');
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw UnionWorkspaceException('${errors.first['message']}');
    }
    final data = body['data'];
    final ws = data is Map ? data['workspaceConfig'] : null;
    final name = ws is Map ? ws['name']?.toString().trim() ?? '' : '';
    if (name.isEmpty) return null;
    final projects = data['projects'];
    return UnionWorkspace(
      name: name,
      version: (ws['version']?.toString().trim().isNotEmpty ?? false)
          ? ws['version'].toString()
          : '1.0.0',
      projectCount: projects is List ? projects.length : 0,
    );
  }

  /// Writes `.shepherd/workspace.yaml` in [dir] unless one is already there.
  /// Returns false when it was left alone.
  static bool write(UnionWorkspace ws, Directory dir) {
    final file = File(p.join(dir.path, '.shepherd', 'workspace.yaml'));
    if (file.existsSync()) return false;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(YamlWriter().write({
      'workspace': {
        'name': ws.name,
        'version': ws.version,
        'team_members': <String>[],
        'squads': <String>[],
        'projects': <String, dynamic>{},
      }
    }));
    return true;
  }
}

class UnionWorkspaceException implements Exception {
  final String message;
  UnionWorkspaceException(this.message);
  @override
  String toString() => message;
}
