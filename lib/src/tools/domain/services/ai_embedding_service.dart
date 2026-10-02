import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'ai_config_service.dart';
import 'ollama_url_helper.dart';

/// Service responsible for generating embedding vectors for text and code.
/// Supports Ollama/LAN AI, Gemini, OpenAI, and a 100% offline deterministic local vectorizer.
class AiEmbeddingService {
  final AiConfigService _configService;
  final http.Client _client;

  /// Which backend produced the last vector: ollama | gemini | openai | local.
  /// Vectors from different sources live in different spaces and must not be mixed.
  String lastSource = 'local';

  AiEmbeddingService({
    AiConfigService? configService,
    http.Client? client,
  })  : _configService = configService ?? AiConfigService(),
        _client = client ?? http.Client();

  /// Generates an embedding vector for the provided [text].
  Future<List<double>> getEmbedding(String text, {AiConfigModel? config}) async {
    final cfg = config ?? _configService.load();
    if (cfg != null) {
      // 1. Try Ollama / LAN AI if active or configured
      final ollamaConfig = cfg.providers['ollama'];
      final isOllamaActive = cfg.activeProvider.toLowerCase() == 'ollama';
      if (isOllamaActive || (ollamaConfig != null && ollamaConfig.baseUrl != null)) {
        final baseUrl = OllamaUrlHelper.normalize(ollamaConfig?.baseUrl);
        final vector = await _tryOllamaEmbedding(baseUrl, text);
        if (vector != null && vector.isNotEmpty) {
          lastSource = 'ollama';
          return vector;
        }
      }

      // 2. Try Google Gemini if API key is provided
      final geminiConfig = cfg.providers['gemini'];
      if (geminiConfig?.apiKey != null && geminiConfig!.apiKey!.isNotEmpty) {
        final vector = await _tryGeminiEmbedding(geminiConfig.apiKey!, text);
        if (vector != null && vector.isNotEmpty) {
          lastSource = 'gemini';
          return vector;
        }
      }

      // 3. Try OpenAI if API key is provided
      final openAiConfig = cfg.providers['openai'];
      if (openAiConfig?.apiKey != null && openAiConfig!.apiKey!.isNotEmpty) {
        final vector = await _tryOpenAiEmbedding(openAiConfig.apiKey!, text);
        if (vector != null && vector.isNotEmpty) {
          lastSource = 'openai';
          return vector;
        }
      }
    }

    // Fallback: Ultra-fast deterministic local vectorizer (128-dim)
    lastSource = 'local';
    return computeLocalDenseVector(text);
  }

  /// Generates embeddings for a batch list of texts.
  Future<List<List<double>>> getBatchEmbeddings(
    List<String> texts, {
    AiConfigModel? config,
  }) async {
    final results = <List<double>>[];
    for (final text in texts) {
      final emb = await getEmbedding(text, config: config);
      results.add(emb);
    }
    return results;
  }

  Future<List<double>?> _tryOllamaEmbedding(String baseUrl, String text) async {
    try {
      final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      final uri = Uri.parse('$cleanBase/api/embeddings');
      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'nomic-embed-text',
              'prompt': text,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['embedding'] is List) {
          return (data['embedding'] as List).map((e) => (e as num).toDouble()).toList();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<double>?> _tryGeminiEmbedding(String apiKey, String text) async {
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=$apiKey',
      );
      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'content': {
                'parts': [
                  {'text': text}
                ]
              }
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['embedding'] is Map && data['embedding']['values'] is List) {
          return (data['embedding']['values'] as List)
              .map((e) => (e as num).toDouble())
              .toList();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<double>?> _tryOpenAiEmbedding(String apiKey, String text) async {
    try {
      final uri = Uri.parse('https://api.openai.com/v1/embeddings');
      final res = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': 'text-embedding-3-small',
              'input': text,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is List && (data['data'] as List).isNotEmpty) {
          final first = (data['data'] as List).first;
          if (first is Map && first['embedding'] is List) {
            return (first['embedding'] as List).map((e) => (e as num).toDouble()).toList();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Deterministic local vectorizer (128 dimensions) with L2 normalization.
  /// Extracts n-grams and code tokens with frequency weights for offline semantic search.
  static List<double> computeLocalDenseVector(String text, {int dimensions = 128}) {
    final vector = List<double>.filled(dimensions, 0.0);
    if (text.trim().isEmpty) return vector;

    final lower = text.toLowerCase();
    // Tokenize by words and symbols
    final tokens = lower.split(RegExp(r'[^a-z0-9_\-\$]')).where((t) => t.isNotEmpty);

    for (final token in tokens) {
      final h = _hashString(token);
      final idx = h.abs() % dimensions;
      final weight = math.log(1.0 + token.length);
      vector[idx] += weight;

      // Token 3-grams
      if (token.length >= 3) {
        for (var i = 0; i <= token.length - 3; i++) {
          final gram = token.substring(i, i + 3);
          final gHash = _hashString(gram);
          final gIdx = gHash.abs() % dimensions;
          vector[gIdx] += 0.5;
        }
      }
    }

    // L2 normalization to ensure unit vectors (norm = 1.0)
    double sumSq = 0.0;
    for (final val in vector) {
      sumSq += val * val;
    }

    if (sumSq > 0) {
      final norm = math.sqrt(sumSq);
      for (var i = 0; i < dimensions; i++) {
        vector[i] = vector[i] / norm;
      }
    }

    return vector;
  }

  static int _hashString(String str) {
    var hash = 5381;
    for (var i = 0; i < str.length; i++) {
      hash = ((hash << 5) + hash) + str.codeUnitAt(i);
      hash = hash & 0x7fffffff;
    }
    return hash;
  }
}
