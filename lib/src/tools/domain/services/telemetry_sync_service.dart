import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

import 'package:yaml_writer/yaml_writer.dart';

class TelemetrySyncService {
  Future<void> syncTelemetry(Set<String> pageKeys) async {
    final token = _getGlobalToken();
    if (token == null) {
      print('⚠️ Global Session not found. Please run `shepherd login` to authenticate. Skipping sync.');
      return;
    }

    final projectId = _getLocalProjectId();
    if (projectId == null) {
      print('⚠️ Project ID not found in .shepherd/config.yaml. Make sure you selected a project during `shepherd login`. Skipping sync.');
      return;
    }
    
    final env = _getGlobalEnv() ?? 'prod';
    final bffUrl = env == 'uat'
        ? 'https://union-uat.shepherdplatform.com/graphql'
        : 'https://union.shepherdplatform.com/graphql';

    print('📡 Fetching project credentials...');
    
    // 1. Fetch apiKey from BFF
    final apiKey = await _fetchApiKey(bffUrl, token, projectId);
    if (apiKey == null) {
      print('⚠️ Could not fetch API Key for project $projectId. Skipping sync.');
      return;
    }

    // 2. Fetch Server Revision (OCC Check)
    final serverRevision = await _fetchServerRevision(bffUrl, token, apiKey);
    final localRevision = _getLocalRevision();
    
    if (serverRevision != null && localRevision < serverRevision) {
      print('❌ Conflito de Sincronização!');
      print('A nuvem possui informações mais recentes (Nuvem: $serverRevision > Local: $localRevision).');
      print('Faça um `git pull` para obter a versão mais recente antes de rodar `shepherd gen` novamente.');
      return;
    }

    print('📡 Syncing mapped UI components with Shepherd Union...');

    final List<Map<String, String>> inputPages = pageKeys.map((id) => {
      "id": id,
      "name": "Mapped Screen $id",
      "path": "Discovered automatically"
    }).toList();

    final mutation = '''
      mutation SyncTelemetry(\$input: SyncTelemetryInput!) {
        syncTelemetry(input: \$input) {
          success
          syncedCount
          message
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(bffUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'query': mutation,
          'variables': {
            'input': {
              'apiKey': apiKey,
              'revision': localRevision,
              'pages': inputPages
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['errors'] != null) {
          print('❌ Sync failed: \${body["errors"][0]["message"]}');
        } else {
          final syncData = body['data']?['syncTelemetry'];
          final success = syncData?['success'] ?? false;
          final count = syncData?['syncedCount'] ?? 0;
          final message = syncData?['message'] ?? '';
          
          if (success) {
            print('✅ Telemetry sync successful. $count pages updated.');
            _saveLocalRevision(localRevision + 1);
          } else {
            print('❌ Sync failed: $message');
          }
        }
      } else {
        print('❌ Telemetry sync failed with status: \${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error syncing telemetry: \$e');
    }
  }

  int _getLocalRevision() {
    final stateFile = File('.shepherd/sync_state.yaml');
    if (!stateFile.existsSync()) return 0;
    final content = stateFile.readAsStringSync();
    if (content.trim().isEmpty) return 0;
    final loaded = loadYaml(content);
    if (loaded is YamlMap && loaded.containsKey('revision')) {
      return (loaded['revision'] as num).toInt();
    }
    return 0;
  }

  void _saveLocalRevision(int revision) {
    final stateFile = File('.shepherd/sync_state.yaml');
    if (!stateFile.parent.existsSync()) {
      stateFile.parent.createSync(recursive: true);
    }
    final yamlWriter = YamlWriter();
    final yamlString = yamlWriter.write({'revision': revision});
    stateFile.writeAsStringSync(yamlString);
  }

  Future<int?> _fetchServerRevision(String url, String token, String apiKey) async {
    const query = """
      query TelemetrySyncRevision(\$apiKey: String!) {
        telemetrySyncRevision(apiKey: \$apiKey)
      }
    """;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$token',
        },
        body: jsonEncode({
          'query': query,
          'variables': {
            'apiKey': apiKey
          }
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final revision = body['data']?['telemetrySyncRevision'];
        if (revision != null) {
          return (revision as num).toInt();
        }
      }
    } catch (e) {
      // Return null on failure
    }
    return null;
  }

  String? _getGlobalToken() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return null;
    final sessionFile = File(p.join(home, '.shepherd_cli', 'session.yaml'));
    if (!sessionFile.existsSync()) return null;
    final content = sessionFile.readAsStringSync();
    if (content.trim().isEmpty) return null;
    final loaded = loadYaml(content);
    if (loaded is YamlMap && loaded.containsKey('token')) {
      return loaded['token'] as String;
    }
    return null;
  }

  String? _getGlobalEnv() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return null;
    final sessionFile = File(p.join(home, '.shepherd_cli', 'session.yaml'));
    if (!sessionFile.existsSync()) return null;
    final content = sessionFile.readAsStringSync();
    if (content.trim().isEmpty) return null;
    final loaded = loadYaml(content);
    if (loaded is YamlMap && loaded.containsKey('env')) {
      return loaded['env'] as String;
    }
    return null;
  }

  String? _getLocalProjectId() {
    final configFile = File('.shepherd/config.yaml');
    if (!configFile.existsSync()) return null;
    final content = configFile.readAsStringSync();
    if (content.trim().isEmpty) return null;
    final loaded = loadYaml(content);
    if (loaded is YamlMap && loaded.containsKey('project_id')) {
      return loaded['project_id'] as String;
    }
    return null;
  }

  Future<String?> _fetchApiKey(String url, String token, String projectId) async {
    const projectsQuery = """
      query {
        projects {
          id
          apiKey
        }
      }
    """;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'query': projectsQuery}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final projects = body['data']?['projects'] as List<dynamic>?;
        if (projects != null) {
          for (var p in projects) {
            if (p['id'] == projectId) {
              return p['apiKey'] as String?;
            }
          }
        }
      }
    } catch (e) {
      // Return null on failure
    }
    return null;
  }
}
