import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import '../../domain/entities/ai_token_usage_entity.dart';

class AiTelemetryService {
  static const String _shepherdKey = 'Shepherd-Secret-Key-2026-Alpha';

  /// Envia telemetria assíncrona (fire-and-forget) para o Shepherd Union / BFF,
  /// registrando consumo de tokens (local gratuito vs API pago) e uso de RAG.
  Future<void> sendAiTelemetry({
    required String provider,
    required String model,
    required int durationMs,
    required AiTokenUsageEntity? tokens,
    int ragResultCount = 0,
    String? taskId,
  }) async {
    try {
      final token = _getSessionToken();
      final corpId = _getCorporationId();
      final env = _getSessionEnv();

      // Se o usuário não estiver logado no Shepherd Union, ignora silenciosamente
      if (token == null || corpId == null) return;

      final projectId = _getLocalProjectId();
      final personId = _getPersonId();

      final bffUrl = env == 'uat'
          ? 'https://union-uat.shepherdplatform.com/graphql'
          : 'https://union.shepherdplatform.com/graphql';

      final timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final events = <Map<String, dynamic>>[];

      // 1. Evento de chamada LLM
      events.add({
        'kind': 'llm_call',
        'providerId': provider.toLowerCase(),
        'providerType': provider.toLowerCase(),
        'providerCategory': tokens?.isLocal == true ? 'local' : 'remote',
        'model': model,
        'agentRole': 'cli_user',
        if (taskId != null) 'taskId': taskId,
        'promptTokens': tokens?.promptTokens ?? 0,
        'completionTokens': tokens?.completionTokens ?? 0,
        'totalTokens': tokens?.totalTokens ?? 0,
        'durationMs': durationMs,
        'timestamp': timestamp,
      });

      // 2. Evento de operação de memória / RAG Local (se houve arquivos/contexto injetados)
      if (ragResultCount > 0) {
        events.add({
          'kind': 'memory_op',
          'operation': 'context_injection',
          'memoryKind': 'rag',
          'resultCount': ragResultCount,
          'agentRole': 'cli_user',
          if (taskId != null) 'taskId': taskId,
          'durationMs': 10,
          'timestamp': timestamp,
        });
      }

      const mutation = r'''
        mutation SendAITelemetry($input: AITelemetryInput!) {
          sendAITelemetry(input: $input) {
            success
            count
          }
        }
      ''';

      final payload = {
        'query': mutation,
        'variables': {
          'input': {
            'corporationId': corpId,
            if (projectId != null) 'projectId': projectId,
            if (personId != null) 'personId': personId,
            'events': events,
          },
        },
      };

      await http.post(
        Uri.parse(bffUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': token,
          'X-Corporation-Id': corpId,
          'X-Shepherd-Key': _shepherdKey,
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      // Falha silenciosa para nunca interromper a experiência do desenvolvedor
    }
  }

  String? _getSessionToken() {
    return _readYamlField('.shepherd/session.yaml', 'token');
  }

  String? _getCorporationId() {
    return _readYamlField('.shepherd/session.yaml', 'corporationId');
  }

  String? _getPersonId() {
    return _readYamlField('.shepherd/session.yaml', 'personId') ??
        _readYamlField('.shepherd/session.yaml', 'userId');
  }

  String? _getSessionEnv() {
    return _readYamlField('.shepherd/session.yaml', 'env');
  }

  String? _getLocalProjectId() {
    return _readYamlField('.shepherd/config.yaml', 'project_id') ??
        _readYamlField('.shepherd/project.yaml', 'id');
  }

  String? _readYamlField(String filePath, String key) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;
      final content = file.readAsStringSync().trim();
      if (content.isEmpty) return null;
      final loaded = loadYaml(content);
      if (loaded is YamlMap && loaded.containsKey(key)) {
        return loaded[key]?.toString();
      }
    } catch (_) {}
    return null;
  }
}
