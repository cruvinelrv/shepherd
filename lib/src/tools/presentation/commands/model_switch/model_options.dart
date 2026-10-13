import '../../../../utils/ansi_colors.dart';
import '../../../data/models/ai_config_model.dart';
import '../../../domain/services/ai_config_service.dart';
import '../../../domain/services/ai_model_catalog_service.dart';
import '../../../domain/services/ai_settings_resolver.dart';
import '../../../domain/services/ollama_url_helper.dart';

class ModelSwitchOption {
  final String label;
  final String provider;
  final String model;
  final String? apiKey;
  final String? baseUrl;
  final bool isLocal;
  final List<String> aliases;

  const ModelSwitchOption({
    required this.label,
    required this.provider,
    required this.model,
    this.apiKey,
    this.baseUrl,
    required this.isLocal,
    this.aliases = const [],
  });
}

Future<List<ModelSwitchOption>> buildModelSwitchOptions(
    AiConfigModel? aiConfig) async {
  final options = <ModelSwitchOption>[];

  // 1. Local (Ollama)
  final ollamaCfg = aiConfig?.providers['ollama'];
  final localModel =
      aiConfig?.local?.model ?? ollamaCfg?.defaultModel ?? 'llama3.1';
  final localUrl = OllamaUrlHelper.normalize(ollamaCfg?.baseUrl);
  final isRemoteLan =
      !localUrl.contains('localhost') && !localUrl.contains('127.0.0.1');
  final lanBadge = isRemoteLan ? ' (LAN: $localUrl)' : '';
  options.add(ModelSwitchOption(
    label:
        '${AnsiColors.brightGreen}🏠 Local (Ollama)${AnsiColors.reset}       : Escolher modelo do Ollama [RAG Ativo / Custo Zero] (Atual: $localModel$lanBadge)',
    provider: 'ollama',
    model: localModel,
    baseUrl: localUrl,
    isLocal: true,
    aliases: ['1', 'local', 'ollama', 'lan'],
  ));

  // 2. OpenAI (ChatGPT)
  final openAiCfg = aiConfig?.providers['openai'];
  final openAiModel = openAiCfg?.defaultModel ?? 'gpt-4o';
  final openAiKey = openAiCfg?.apiKey ?? resolveAiEnvApiKey('openai');
  options.add(ModelSwitchOption(
    label:
        '${AnsiColors.brightYellow}🌐 OpenAI (ChatGPT)${AnsiColors.reset}     : $openAiModel [Econômico / Nuvem]',
    provider: 'openai',
    model: openAiModel,
    apiKey: openAiKey,
    isLocal: false,
    aliases: ['2', 'openai', 'chatgpt', 'chat_gpt', 'chat-gpt', 'gpt'],
  ));

  // 3. Anthropic (Claude)
  final claudeCfg = aiConfig?.providers['anthropic'];
  final claudeModel = claudeCfg?.defaultModel ?? 'claude-sonnet-5';
  final claudeKey = claudeCfg?.apiKey ?? resolveAiEnvApiKey('anthropic');
  options.add(ModelSwitchOption(
    label:
        '${AnsiColors.brightBlue}🟣 Anthropic (Claude)${AnsiColors.reset}   : $claudeModel [Raciocínio / Nuvem]',
    provider: 'anthropic',
    model: claudeModel,
    apiKey: claudeKey,
    isLocal: false,
    aliases: ['3', 'anthropic', 'claude'],
  ));

  // 4. Google (Gemini)
  final geminiCfg = aiConfig?.providers['gemini'];
  final geminiModel = aiConfig?.medium?.model ??
      geminiCfg?.defaultModel ??
      AiModelCatalogService.defaultGeminiModel;
  final geminiKey = geminiCfg?.apiKey ?? resolveAiEnvApiKey('gemini');
  options.add(ModelSwitchOption(
    label:
        '${AnsiColors.brightCyan}🔷 Google (Gemini)${AnsiColors.reset}      : $geminiModel [Rápido / Nuvem]',
    provider: 'gemini',
    model: geminiModel,
    apiKey: geminiKey,
    isLocal: false,
    aliases: ['4', 'gemini', 'google'],
  ));

  // 5. OpenCode Zen (opencode.ai)
  final openCodeCfg = aiConfig?.providers['opencode'];
  final openCodeModel = openCodeCfg?.defaultModel ?? 'qwen3.8-max';
  final openCodeKey = openCodeCfg?.apiKey ?? resolveAiEnvApiKey('opencode');
  final openCodeUrl = openCodeCfg?.baseUrl ?? 'https://opencode.ai/zen/v1';
  options.add(ModelSwitchOption(
    label:
        '${AnsiColors.brightMagenta}⚡ OpenCode Zen (opencode.ai)${AnsiColors.reset} : Escolher modelo [qwen, deepseek, claude, gpt...] (Atual: $openCodeModel)',
    provider: 'opencode',
    model: openCodeModel,
    apiKey: openCodeKey,
    baseUrl: openCodeUrl,
    isLocal: false,
    aliases: ['5', 'opencode', 'opencode.ai', 'zen'],
  ));

  // 6. Servidor Local / LAN Customizado (LocalAI / vLLM / LMStudio / Ollama LAN)
  final localAiCfg =
      aiConfig?.providers['local_ai'] ?? aiConfig?.providers['lan_ai'];
  final localAiModel = localAiCfg?.defaultModel ?? 'local-model';
  final localAiUrl = localAiCfg?.baseUrl ?? 'http://localhost:8080';
  options.add(ModelSwitchOption(
    label:
        '${AnsiColors.brightWhite}🖥️ Servidor Local (LAN)${AnsiColors.reset}     : $localAiModel [RAG Ativo / LAN] ($localAiUrl)',
    provider: 'local_ai',
    model: localAiModel,
    baseUrl: localAiUrl,
    isLocal: true,
    aliases: ['6', 'local_ai', 'localai', 'lan_ai'],
  ));

  return options;
}

String providerDisplayName(String provider) {
  switch (provider.toLowerCase()) {
    case 'gemini':
      return 'Google Gemini (Direto)';
    case 'openai':
      return 'OpenAI (Direto)';
    case 'anthropic':
      return 'Anthropic Claude (Direto)';
    case 'opencode':
    case 'zen':
      return 'OpenCode Zen (opencode.ai)';
    case 'ollama':
      return 'Ollama (Local / Rede Local)';
    case 'local_ai':
    case 'lan_ai':
      return 'Servidor Local / Rede Local';
    default:
      return provider;
  }
}
