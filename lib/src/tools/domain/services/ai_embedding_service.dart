import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'ai_config_service.dart';

/// Serviço responsável por gerar vetores de embedding para textos e códigos.
/// Suporta Ollama/LAN AI, Gemini, OpenAI e um vetorizador local determinístico 100% offline.
class AiEmbeddingService {
  final AiConfigService _configService;
  final http.Client _client;

  AiEmbeddingService({
    AiConfigService? configService,
    http.Client? client,
  })  : _configService = configService ?? AiConfigService(),
        _client = client ?? http.Client();

  /// Gera um vetor de embedding para o [text] fornecido.
  Future<List<double>> getEmbedding(String text, {AiConfigModel? config}) async {
    final cfg = config ?? _configService.load();
    if (cfg != null) {
      // 1. Tentar Ollama / LAN AI se estiver ativo ou configurado
      final ollamaConfig = cfg.providers['ollama'];
      final isOllamaActive = cfg.activeProvider.toLowerCase() == 'ollama';
      if (isOllamaActive || (ollamaConfig != null && ollamaConfig.baseUrl != null)) {
        final baseUrl = ollamaConfig?.baseUrl ?? 'http://localhost:11434';
        final vector = await _tryOllamaEmbedding(baseUrl, text);
        if (vector != null && vector.isNotEmpty) return vector;
      }

      // 2. Tentar Google Gemini se houver API key
      final geminiConfig = cfg.providers['gemini'];
      if (geminiConfig?.apiKey != null && geminiConfig!.apiKey!.isNotEmpty) {
        final vector = await _tryGeminiEmbedding(geminiConfig.apiKey!, text);
        if (vector != null && vector.isNotEmpty) return vector;
      }

      // 3. Tentar OpenAI se houver API key
      final openAiConfig = cfg.providers['openai'];
      if (openAiConfig?.apiKey != null && openAiConfig!.apiKey!.isNotEmpty) {
        final vector = await _tryOpenAiEmbedding(openAiConfig.apiKey!, text);
        if (vector != null && vector.isNotEmpty) return vector;
      }
    }

    // Fallback: Vetorizador Local Determinístico ultrarrápido (128-dim)
    return computeLocalDenseVector(text);
  }

  /// Gera embeddings para uma lista de textos em lote.
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

  /// Vetorizador determinístico local (128 dimensões) com normalização L2.
  /// Extrai n-gramas e tokens de código com pesos de frequência para busca semântica offline.
  static List<double> computeLocalDenseVector(String text, {int dimensions = 128}) {
    final vector = List<double>.filled(dimensions, 0.0);
    if (text.trim().isEmpty) return vector;

    final lower = text.toLowerCase();
    // Tokens por palavras e símbolos
    final tokens = lower.split(RegExp(r'[^a-z0-9_\-\$]')).where((t) => t.isNotEmpty);

    for (final token in tokens) {
      final h = _hashString(token);
      final idx = h.abs() % dimensions;
      final weight = math.log(1.0 + token.length);
      vector[idx] += weight;

      // 3-grams do token
      if (token.length >= 3) {
        for (var i = 0; i <= token.length - 3; i++) {
          final gram = token.substring(i, i + 3);
          final gHash = _hashString(gram);
          final gIdx = gHash.abs() % dimensions;
          vector[gIdx] += 0.5;
        }
      }
    }

    // Normalização L2 para garantir vetores unitários (norma = 1.0)
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
