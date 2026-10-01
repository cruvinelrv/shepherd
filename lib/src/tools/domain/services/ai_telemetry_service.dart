import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import '../../domain/entities/ai_mcp_tool_call_entity.dart';
import '../../domain/entities/ai_token_usage_entity.dart';

class AiTelemetryService {
  static const String _shepherdKey = 'Shepherd-Secret-Key-2026-Alpha';

  /// Sends asynchronous (fire-and-forget) telemetry to Shepherd Union / BFF,
  /// tracking token usage (local free vs API paid), model profiles, RAG and tool usage.
  Future<void> sendAiTelemetry({
    required String provider,
    required String model,
    required int durationMs,
    required AiTokenUsageEntity? tokens,
    int ragResultCount = 0,
    int toolCallsCount = 0,
    List<AiMcpToolCallEntity>? mcpToolCalls,
    String? profile,
    String? taskId,
  }) async {
    try {
      final token = _getSessionToken();
      final corpId = _getCorporationId();
      final env = _getSessionEnv();

      // Silently ignore if user is not logged into Shepherd Union
      if (token == null || corpId == null) return;

      final projectId = _getLocalProjectId();
      final personId = _getPersonId();

      final bffUrl = env == 'uat'
          ? 'https://union-uat.shepherdplatform.com/graphql'
          : 'https://union.shepherdplatform.com/graphql';

      final timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final events = <Map<String, dynamic>>[];

      final effectiveToolCallsCount = toolCallsCount > 0
          ? toolCallsCount
          : (mcpToolCalls?.length ?? 0);

      // 1. LLM call event
      events.add({
        'kind': 'llm_call',
        'providerId': provider.toLowerCase(),
        'providerType': provider.toLowerCase(),
        'providerCategory': tokens?.isLocal == true ? 'local' : 'remote',
        'model': model,
        if (profile != null && profile.isNotEmpty) 'profile': profile,
        'agentRole': 'cli_user',
        if (taskId != null) 'taskId': taskId,
        'promptTokens': tokens?.promptTokens ?? 0,
        'completionTokens': tokens?.completionTokens ?? 0,
        'totalTokens': tokens?.totalTokens ?? 0,
        'isEstimated': tokens?.isEstimated ?? false,
        if (effectiveToolCallsCount > 0) 'toolCallsCount': effectiveToolCallsCount,
        'durationMs': durationMs,
        'timestamp': timestamp,
      });

      // 2. Memory operation event / Local RAG (if files/context were injected)
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

      // 3. MCP tool call events (if workspace tools were triggered)
      if (mcpToolCalls != null && mcpToolCalls.isNotEmpty) {
        for (final call in mcpToolCalls) {
          events.add({
            'kind': 'mcp_tool_call',
            'serverId': call.serverName,
            'toolName': call.toolName,
            'success': true,
            'agentRole': 'cli_user',
            if (taskId != null) 'taskId': taskId,
            'timestamp': timestamp,
          });
        }
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
      // Silent failure to avoid interrupting the developer experience
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
