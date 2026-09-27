import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class AiDirectInferenceService {
  /// Gera resposta em streaming diretamente com o provedor configurado pelo desenvolvedor.
  Stream<String> generateStream({
    required String prompt,
    required String provider,
    required String model,
    String? apiKey,
    String? baseUrl,
  }) async* {
    final normProvider = provider.toLowerCase();

    if (normProvider == 'gemini') {
      yield* _generateGeminiStream(prompt, model, apiKey);
    } else if (normProvider == 'ollama') {
      yield* _generateOllamaStream(prompt, model, baseUrl);
    } else if (normProvider == 'openai') {
      yield* _generateOpenAiStream(prompt, model, apiKey);
    } else if (normProvider == 'anthropic') {
      yield* _generateAnthropicStream(prompt, model, apiKey);
    } else {
      throw UnsupportedError('Provedor de IA "$provider" não suportado.');
    }
  }

  Stream<String> _generateGeminiStream(
    String prompt,
    String modelName,
    String? apiKey,
  ) async* {
    final key = apiKey ?? Platform.environment['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError(
        'Chave de API do Gemini não configurada. '
        'Execute `shepherd ai config` ou exporte GEMINI_API_KEY.',
      );
    }

    final model = GenerativeModel(model: modelName, apiKey: key);
    final responseStream = model.generateContentStream([Content.text(prompt)]);

    await for (final chunk in responseStream) {
      if (chunk.text != null && chunk.text!.isNotEmpty) {
        yield chunk.text!;
      }
    }
  }

  Stream<String> _generateOllamaStream(
    String prompt,
    String modelName,
    String? baseUrl,
  ) async* {
    final host = baseUrl != null && baseUrl.isNotEmpty ? baseUrl : 'http://localhost:11434';
    final uri = Uri.parse('$host/api/generate');

    final client = http.Client();
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': modelName,
      'prompt': prompt,
      'stream': true,
    });

    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        throw StateError('Ollama error (${response.statusCode}): $errBody');
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final chunk = json['response']?.toString();
          if (chunk != null && chunk.isNotEmpty) {
            yield chunk;
          }
        } catch (_) {}
      }
    } finally {
      client.close();
    }
  }

  Stream<String> _generateOpenAiStream(
    String prompt,
    String modelName,
    String? apiKey,
  ) async* {
    final key = apiKey ?? Platform.environment['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError(
        'Chave de API da OpenAI não configurada. '
        'Execute `shepherd ai config` ou exporte OPENAI_API_KEY.',
      );
    }

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final client = http.Client();
    final request = http.Request('POST', uri);
    request.headers['Authorization'] = 'Bearer $key';
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': modelName,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'stream': true,
    });

    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        throw StateError('OpenAI error (${response.statusCode}): $errBody');
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final data = trimmed.replaceFirst('data:', '').trim();
        if (data == '[DONE]') break;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content']?.toString();
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          }
        } catch (_) {}
      }
    } finally {
      client.close();
    }
  }

  Stream<String> _generateAnthropicStream(
    String prompt,
    String modelName,
    String? apiKey,
  ) async* {
    final key = apiKey ?? Platform.environment['ANTHROPIC_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError(
        'Chave de API da Anthropic não configurada. '
        'Execute `shepherd ai config` ou exporte ANTHROPIC_API_KEY.',
      );
    }

    final uri = Uri.parse('https://api.anthropic.com/v1/messages');
    final client = http.Client();
    final request = http.Request('POST', uri);
    request.headers['x-api-key'] = key;
    request.headers['anthropic-version'] = '2023-06-01';
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': modelName,
      'max_tokens': 4096,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'stream': true,
    });

    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        throw StateError('Anthropic error (${response.statusCode}): $errBody');
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final data = trimmed.replaceFirst('data:', '').trim();
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          if (json['type'] == 'content_block_delta') {
            final delta = json['delta'] as Map<String, dynamic>?;
            final text = delta?['text']?.toString();
            if (text != null && text.isNotEmpty) {
              yield text;
            }
          }
        } catch (_) {}
      }
    } finally {
      client.close();
    }
  }
}
