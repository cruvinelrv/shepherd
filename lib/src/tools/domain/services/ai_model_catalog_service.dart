import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ollama_url_helper.dart';

class AiModelCatalogService {
  static const Map<String, List<String>> defaultModels = {
    'gemini': [
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-3.8-flash',
      'gemini-2.0-flash',
    ],
    'openai': [
      'gpt-4o',
      'gpt-4o-mini',
      'o3-mini',
      'o1',
      'gpt-4-turbo',
    ],
    'anthropic': [
      'claude-sonnet-5',
      'claude-sonnet-4-6',
      'claude-opus-4-6',
      'claude-3-7-sonnet',
      'claude-3-5-sonnet',
      'claude-3-5-haiku',
    ],
    'ollama': [
      'qwen2.5-coder:14b',
      'qwen2.5-coder:7b',
      'deepseek-r1:14b',
      'gemma3:12b',
      'llama3.1',
      'deepseek-r1',
      'mistral',
      'codellama',
    ],
    'opencode': [
      'qwen3.8-max',
      'deepseek-v4.1-flash',
      'deepseek-v4-pro',
      'gpt-5',
      'gpt-5.1',
      'claude-sonnet-5',
      'claude-opus-5',
      'gemini-3.8-flash',
      'minimax-m3',
      'glm-5.3',
      'kimi-k3',
    ],
    'local_ai': [
      'llama-3.2-3b',
      'deepseek-r1-distill-qwen-7b',
      'qwen2.5-coder-7b',
      'mistral-7b-instruct',
      'local-model',
    ],
  };

  /// Returns known models for a provider by combining default models
  /// and any user-added or saved models.
  static List<String> getKnownModels(String providerId, {List<String>? userModels}) {
    final defaults = defaultModels[providerId.toLowerCase()] ?? [];
    final set = <String>{...defaults};
    if (userModels != null) {
      set.addAll(userModels);
    }
    return set.toList();
  }

  /// Fetches the updated model list directly from the provider's API in real time.
  Future<List<String>> fetchOnlineModels({
    required String providerId,
    String? apiKey,
    String? baseUrl,
  }) async {
    final normProvider = providerId.toLowerCase();

    try {
      if (normProvider == 'gemini') {
        if (apiKey == null || apiKey.isEmpty) return [];
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final list = data['models'] as List<dynamic>? ?? [];
          final models = <String>[];
          for (final item in list) {
            final name = item['name']?.toString() ?? '';
            final cleanName = name.replaceFirst('models/', '');
            final methods = item['supportedGenerationMethods'] as List<dynamic>? ?? [];
            if (methods.contains('generateContent') && !cleanName.contains('embedding')) {
              models.add(cleanName);
            }
          }
          models.sort();
          return models;
        }
      } else if (normProvider == 'openai' && (baseUrl == null || baseUrl.isEmpty)) {
        if (apiKey == null || apiKey.isEmpty) return [];
        final uri = Uri.parse('https://api.openai.com/v1/models');
        final resp = await http.get(uri, headers: {
          'Authorization': 'Bearer $apiKey',
        }).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final list = data['data'] as List<dynamic>? ?? [];
          final models = <String>[];
          for (final item in list) {
            final id = item['id']?.toString() ?? '';
            if (id.startsWith('gpt-') || id.startsWith('o1') || id.startsWith('o3') || id.startsWith('chatgpt-')) {
              models.add(id);
            }
          }
          models.sort();
          return models;
        }
      } else if (normProvider == 'anthropic') {
        if (apiKey == null || apiKey.isEmpty) return [];
        final uri = Uri.parse('https://api.anthropic.com/v1/models');
        final resp = await http.get(uri, headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        }).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final list = data['data'] as List<dynamic>? ?? [];
          final models = <String>[];
          for (final item in list) {
            final id = item['id']?.toString() ?? '';
            models.add(id);
          }
          models.sort();
          return models;
        }
      } else if (normProvider == 'ollama') {
        final host = OllamaUrlHelper.normalize(baseUrl);
        final uri = Uri.parse('$host/api/tags');
        final resp = await http.get(uri).timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final list = data['models'] as List<dynamic>? ?? [];
          final models = <String>[];
          for (final item in list) {
            final name = item['name']?.toString() ?? '';
            if (name.isNotEmpty) {
              models.add(name);
            }
          }
          models.sort();
          return models;
        }
      } else if (normProvider == 'opencode' ||
          normProvider == 'local_ai' ||
          normProvider == 'lan_ai' ||
          (normProvider == 'openai' && baseUrl != null && baseUrl.isNotEmpty)) {
        final defaultBase = normProvider == 'opencode'
            ? 'https://opencode.ai/zen/v1'
            : 'http://localhost:1234/v1';
        final hostUrl = LanAiHelper.normalize(baseUrl, defaultUrl: defaultBase);
        final uri = Uri.parse(LanAiHelper.buildModelsUrl(hostUrl));
        final headers = <String, String>{};
        if (apiKey != null && apiKey.isNotEmpty) {
          headers['Authorization'] = 'Bearer $apiKey';
        }
        final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final list = (data['data'] ?? data['models']) as List<dynamic>? ?? [];
          final models = <String>[];
          for (final item in list) {
            final id = item['id']?.toString() ?? item['name']?.toString() ?? '';
            if (id.isNotEmpty) models.add(id);
          }
          models.sort();
          return models;
        }
      }
    } catch (_) {
      // Ignore network failures or timeouts and return empty for local fallback
    }

    return [];
  }
}
