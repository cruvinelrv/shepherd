import 'dart:io';

import 'ai_model_catalog_service.dart';

// Names and defaults of the AI providers the CLI knows how to configure: which
// provider a model name belongs to, the default model of a provider, and the
// environment variable that may hold its API key. The AI itself runs in the engine.

String? normalizeAiProvider(String input) {
  final clean = input.trim().toLowerCase();
  if (clean == 'openai' ||
      clean == 'chatgpt' ||
      clean == 'chat_gpt' ||
      clean == 'chat-gpt' ||
      clean == 'gpt') {
    return 'openai';
  }
  if (clean == 'anthropic' || clean == 'claude') {
    return 'anthropic';
  }
  if (clean == 'gemini' || clean == 'google') {
    return 'gemini';
  }
  if (clean == 'opencode' || clean == 'opencode.ai' || clean == 'zen') {
    return 'opencode';
  }
  if (clean == 'ollama' || clean == 'local' || clean == 'lan') {
    return 'ollama';
  }
  if (clean == 'local_ai' || clean == 'localai') {
    return 'local_ai';
  }
  return null;
}

String? inferAiProviderFromModel(String model) {
  final m = model.toLowerCase().trim();
  final norm = normalizeAiProvider(m);
  if (norm != null) return norm;

  if (m.startsWith('gpt-') ||
      m.startsWith('gpt4') ||
      m.startsWith('gpt3') ||
      m.startsWith('o1') ||
      m.startsWith('o3') ||
      m.startsWith('text-embedding')) {
    return 'openai';
  }
  if (m.startsWith('claude') || m.startsWith('sonnet')) {
    return 'anthropic';
  }
  if (m.startsWith('gemini-')) {
    return 'gemini';
  }
  if (m.startsWith('opencode/') || m.startsWith('zen/')) {
    return 'opencode';
  }
  if (m.startsWith('llama') ||
      m.startsWith('mistral') ||
      m.startsWith('deepseek') ||
      m.startsWith('qwen') ||
      m.startsWith('phi') ||
      m.startsWith('codellama') ||
      m.startsWith('nomic') ||
      m.startsWith('gemma')) {
    return 'ollama';
  }
  return null;
}

String defaultAiModelFor(String provider) {
  switch (provider.toLowerCase()) {
    case 'gemini':
    case 'google':
      return AiModelCatalogService.defaultGeminiModel;
    case 'openai':
    case 'chatgpt':
    case 'chat_gpt':
    case 'chat-gpt':
    case 'gpt':
      return 'gpt-4o';
    case 'anthropic':
    case 'claude':
    case 'sonnet':
      return 'claude-sonnet-5';
    case 'opencode':
    case 'opencode.ai':
    case 'zen':
      return 'qwen3.8-max';
    case 'ollama':
    case 'local':
    case 'lan':
      return 'llama3.1';
    case 'local_ai':
    case 'localai':
    case 'lan_ai':
      return 'local-model';
    default:
      return 'default';
  }
}

String? resolveAiEnvApiKey(String provider) {
  switch (provider.toLowerCase()) {
    case 'gemini':
      return Platform.environment['GEMINI_API_KEY'];
    case 'openai':
      return Platform.environment['OPENAI_API_KEY'];
    case 'anthropic':
      return Platform.environment['ANTHROPIC_API_KEY'];
    case 'opencode':
    case 'zen':
      return Platform.environment['OPENCODE_API_KEY'];
    default:
      return null;
  }
}
