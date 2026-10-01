import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../../data/models/ai_token_usage_model.dart';
import '../../domain/entities/ai_token_usage_entity.dart';
import 'ollama_url_helper.dart';

class AiDirectInferenceService {
  /// Generates streaming responses directly with the provider configured by the developer,
  /// emitting accurate token usage telemetry (local free vs API paid) via [onUsage].
  Stream<String> generateStream({
    required String prompt,
    required String provider,
    required String model,
    String? apiKey,
    String? baseUrl,
    void Function(AiTokenUsageEntity usage)? onUsage,
  }) async* {
    final normProvider = provider.toLowerCase();

    if (normProvider == 'gemini') {
      yield* _generateGeminiStream(prompt, model, apiKey, onUsage);
    } else if (normProvider == 'ollama') {
      yield* _generateOllamaStream(prompt, model, baseUrl, onUsage);
    } else if (normProvider == 'openai') {
      yield* _generateOpenAiStream(prompt, model, apiKey, baseUrl, onUsage);
    } else if (normProvider == 'opencode') {
      final key = apiKey ?? Platform.environment['OPENCODE_API_KEY'];
      if (key == null || key.isEmpty) {
        throw StateError(
          'Chave de API do OpenCode Zen não configurada. '
          'Execute `/model` ou `shepherd ai config` ou exporte OPENCODE_API_KEY.',
        );
      }
      final host = (baseUrl != null && baseUrl.trim().isNotEmpty)
          ? baseUrl
          : 'https://opencode.ai/zen/v1';
      yield* _generateOpenAiStream(
        prompt,
        model,
        key,
        host,
        onUsage,
        defaultLocal: false,
      );
    } else if (normProvider == 'local_ai' ||
        normProvider == 'lan_ai' ||
        normProvider == 'custom_openai') {
      yield* _generateOpenAiStream(
        prompt,
        model,
        apiKey,
        baseUrl,
        onUsage,
        defaultLocal: true,
      );
    } else if (normProvider == 'anthropic') {
      yield* _generateAnthropicStream(prompt, model, apiKey, onUsage);
    } else {
      throw UnsupportedError('Provedor de IA "$provider" não suportado.');
    }
  }

  Stream<String> _generateGeminiStream(
    String prompt,
    String modelName,
    String? apiKey,
    void Function(AiTokenUsageEntity usage)? onUsage,
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

    final completionBuffer = StringBuffer();
    int? promptTokens;
    int? completionTokens;

    await for (final chunk in responseStream) {
      if (chunk.text != null && chunk.text!.isNotEmpty) {
        completionBuffer.write(chunk.text!);
        yield chunk.text!;
      }
      if (chunk.usageMetadata != null) {
        promptTokens = chunk.usageMetadata!.promptTokenCount;
        completionTokens = chunk.usageMetadata!.candidatesTokenCount;
      }
    }

    if (onUsage != null) {
      if (promptTokens != null && completionTokens != null) {
        onUsage(AiTokenUsageModel(
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          totalTokens: promptTokens + completionTokens,
          isLocal: false,
        ));
      } else {
        onUsage(AiTokenUsageModel.estimate(
          prompt: prompt,
          completion: completionBuffer.toString(),
          isLocal: false,
        ));
      }
    }
  }

  Stream<String> _generateOllamaStream(
    String prompt,
    String modelName,
    String? baseUrl,
    void Function(AiTokenUsageEntity usage)? onUsage,
  ) async* {
    final host = OllamaUrlHelper.normalize(baseUrl);
    final isLocal = LanAiHelper.isLocalOrLan(host);
    final uri = Uri.parse('$host/api/generate');

    final client = http.Client();
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': modelName,
      'prompt': prompt,
      'stream': true,
    });

    final completionBuffer = StringBuffer();
    int? promptTokens;
    int? completionTokens;

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
            completionBuffer.write(chunk);
            yield chunk;
          }
          if (json.containsKey('prompt_eval_count')) {
            promptTokens = json['prompt_eval_count'] as int?;
          }
          if (json.containsKey('eval_count')) {
            completionTokens = json['eval_count'] as int?;
          }
        } catch (_) {}
      }

      if (onUsage != null) {
        if (promptTokens != null && completionTokens != null) {
          onUsage(AiTokenUsageModel(
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: promptTokens + completionTokens,
            isLocal: isLocal,
          ));
        } else {
          onUsage(AiTokenUsageModel.estimate(
            prompt: prompt,
            completion: completionBuffer.toString(),
            isLocal: isLocal,
          ));
        }
      }
    } on SocketException catch (_) {
      throw StateError(
        'Não foi possível conectar ao Ollama em "$host". '
        'Certifique-se de que o Ollama está rodando (`ollama serve`) ou alterne para outro modelo com `/model` ou `medium`.',
      );
    } catch (e) {
      if (e.toString().contains('Connection refused') || e.toString().contains('SocketException')) {
        throw StateError(
          'Não foi possível conectar ao Ollama em "$host". '
          'Certifique-se de que o Ollama está rodando (`ollama serve`) ou alterne para outro modelo com `/model` ou `medium`.',
        );
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  Stream<String> _generateOpenAiStream(
    String prompt,
    String modelName,
    String? apiKey,
    String? baseUrl,
    void Function(AiTokenUsageEntity usage)? onUsage, {
    bool defaultLocal = false,
  }) async* {
    final hasCustomBaseUrl = baseUrl != null && baseUrl.trim().isNotEmpty;
    final isLocal = defaultLocal || (hasCustomBaseUrl && LanAiHelper.isLocalOrLan(baseUrl));

    final effectiveKey = apiKey ??
        Platform.environment['OPENAI_API_KEY'] ??
        (isLocal ? 'local-ai-key' : null);

    if (!isLocal && (effectiveKey == null || effectiveKey.isEmpty)) {
      throw StateError(
        'Chave de API da OpenAI não configurada. '
        'Execute `shepherd ai config` ou exporte OPENAI_API_KEY.',
      );
    }

    final endpoint = hasCustomBaseUrl
        ? LanAiHelper.buildChatCompletionsUrl(baseUrl)
        : 'https://api.openai.com/v1/chat/completions';

    final uri = Uri.parse(endpoint);
    final client = http.Client();
    final request = http.Request('POST', uri);
    if (effectiveKey != null && effectiveKey.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $effectiveKey';
    }
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': modelName,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'stream': true,
      'stream_options': {'include_usage': true},
    });

    final completionBuffer = StringBuffer();
    int? promptTokens;
    int? completionTokens;

    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        final serverLabel = isLocal ? 'Servidor Local/LAN' : 'OpenAI';
        throw StateError('$serverLabel error (${response.statusCode}): $errBody');
      }

      var hasStartedReasoning = false;
      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final data = trimmed.replaceFirst('data:', '').trim();
        if (data == '[DONE]') {
          if (hasStartedReasoning) {
            yield '</think>';
            hasStartedReasoning = false;
          }
          break;
        }
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final reasoning = delta?['reasoning_content']?.toString() ??
                delta?['reasoning']?.toString();
            if (reasoning != null && reasoning.isNotEmpty) {
              if (!hasStartedReasoning) {
                hasStartedReasoning = true;
                yield '<think>';
              }
              yield reasoning;
            }

            final content = delta?['content']?.toString();
            if (content != null && content.isNotEmpty) {
              if (hasStartedReasoning) {
                hasStartedReasoning = false;
                yield '</think>';
              }
              completionBuffer.write(content);
              yield content;
            }
          }
          if (json.containsKey('usage') && json['usage'] is Map) {
            final usage = json['usage'] as Map;
            promptTokens = usage['prompt_tokens'] as int?;
            completionTokens = usage['completion_tokens'] as int?;
          }
        } catch (_) {}
      }

      if (onUsage != null) {
        if (promptTokens != null && completionTokens != null) {
          onUsage(AiTokenUsageModel(
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: promptTokens + completionTokens,
            isLocal: isLocal,
          ));
        } else {
          onUsage(AiTokenUsageModel.estimate(
            prompt: prompt,
            completion: completionBuffer.toString(),
            isLocal: isLocal,
          ));
        }
      }
    } finally {
      client.close();
    }
  }

  Stream<String> _generateAnthropicStream(
    String prompt,
    String modelName,
    String? apiKey,
    void Function(AiTokenUsageEntity usage)? onUsage,
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

    final completionBuffer = StringBuffer();
    int? promptTokens;
    int? completionTokens;

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
          final type = json['type']?.toString();
          if (type == 'message_start' && json['message'] is Map) {
            final msg = json['message'] as Map;
            if (msg['usage'] is Map) {
              promptTokens = (msg['usage'] as Map)['input_tokens'] as int?;
            }
          }
          if (type == 'message_delta' && json['usage'] is Map) {
            completionTokens = (json['usage'] as Map)['output_tokens'] as int?;
          }
          if (type == 'content_block_delta') {
            final delta = json['delta'] as Map<String, dynamic>?;
            final text = delta?['text']?.toString();
            if (text != null && text.isNotEmpty) {
              completionBuffer.write(text);
              yield text;
            }
          }
        } catch (_) {}
      }

      if (onUsage != null) {
        if (promptTokens != null && completionTokens != null) {
          onUsage(AiTokenUsageModel(
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: promptTokens + completionTokens,
            isLocal: false,
          ));
        } else {
          onUsage(AiTokenUsageModel.estimate(
            prompt: prompt,
            completion: completionBuffer.toString(),
            isLocal: false,
          ));
        }
      }
    } finally {
      client.close();
    }
  }
}
