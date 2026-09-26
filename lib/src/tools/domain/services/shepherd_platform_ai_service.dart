import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import '../../data/models/ai_gateway_response_model.dart';

class ShepherdPlatformAiService {
  final http.Client _client;

  ShepherdPlatformAiService({http.Client? client})
      : _client = client ?? http.Client();

  Map<String, dynamic>? getSession() {
    final sessionFile = File('.shepherd/session.yaml');
    if (!sessionFile.existsSync()) return null;
    final content = sessionFile.readAsStringSync();
    if (content.trim().isEmpty) return null;
    final loaded = loadYaml(content);
    if (loaded is YamlMap) {
      return Map<String, dynamic>.from(loaded);
    }
    return null;
  }

  String resolveGatewayUrl(String? env) {
    final override = Platform.environment['SHEPHERD_AI_GATEWAY_URL'];
    if (override != null && override.isNotEmpty) {
      return override.replaceAll(RegExp(r'/+$'), '');
    }

    if (env == 'uat') {
      return 'https://ai-uat.shepherdplatform.com';
    }
    return 'https://ai.shepherdplatform.com';
  }

  Future<AiGatewayResponseModel> generate({
    required String goal,
    String mode = 'fast',
    String tier = 'fast',
    String? workspaceContext,
    String? projectId,
    List<Map<String, String>>? history,
  }) async {
    final session = getSession();
    final token = session?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const FormatException(
        'Você precisa estar autenticado na Shepherd Platform para usar o Shepherd AI.\n'
        'Execute `shepherd login` para autenticar sua conta.',
      );
    }

    final env = session?['env'] as String?;
    final corporationId = session?['corporationId'] as String?;
    final baseUrl = resolveGatewayUrl(env);

    String? skillsContext;
    final skillsFile = File('.shepherd/skills.yaml');
    if (skillsFile.existsSync()) {
      final content = skillsFile.readAsStringSync().trim();
      if (content.isNotEmpty) skillsContext = content;
    }

    final url = Uri.parse('$baseUrl/api/v1/ai/generate');
    final payload = {
      'goal': goal,
      'mode': mode,
      'tier': tier,
      if (workspaceContext != null) 'workspace_context': workspaceContext,
      if (skillsContext != null) 'skills_context': skillsContext,
      if (projectId != null) 'project_id': projectId,
      if (history != null) 'history': history,
    };

    final stopwatch = Stopwatch()..start();
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Auth-Token': token,
        if (corporationId != null) 'X-Corporation-Id': corporationId,
      },
      body: jsonEncode(payload),
    );
    stopwatch.stop();

    if (response.statusCode == 401) {
      throw const FormatException(
        'Sessão expirada ou não autorizada na Shepherd Platform.\n'
        'Por favor, execute `shepherd login` novamente.',
      );
    }

    if (response.statusCode != 200) {
      throw HttpException(
        'Erro na Shepherd Platform AI (${response.statusCode}): ${response.body}',
        uri: url,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['latency_ms'] == null) {
      data['latency_ms'] = stopwatch.elapsedMilliseconds;
    }
    if (data['provider'] == null) {
      data['provider'] = 'Shepherd Platform';
    }
    if (data['model_used'] == null) {
      data['model_used'] = tier == 'deep' ? 'gemini-1.5-pro' : 'gemini-2.5-flash';
    }
    return AiGatewayResponseModel.fromJson(data);
  }

  Future<Map<String, dynamic>> approvePlan({
    required String taskId,
  }) async {
    final session = getSession();
    final token = session?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const FormatException('Sessão não encontrada.');
    }

    final env = session?['env'] as String?;
    final corporationId = session?['corporationId'] as String?;
    final baseUrl = resolveGatewayUrl(env);

    final url = Uri.parse('$baseUrl/api/v1/ai/approve');
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Auth-Token': token,
        if (corporationId != null) 'X-Corporation-Id': corporationId,
      },
      body: jsonEncode({'task_id': taskId}),
    );

    if (response.statusCode != 200) {
      throw HttpException(
        'Erro ao aprovar plano (${response.statusCode}): ${response.body}',
        uri: url,
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
