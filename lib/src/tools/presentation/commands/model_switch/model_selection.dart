import '../../../data/models/ai_config_model.dart';
import '../../../domain/services/ai_config_service.dart';
import '../../../domain/services/ai_model_catalog_service.dart';
import '../../../domain/services/ai_settings_resolver.dart';
import '../../../domain/services/ollama_url_helper.dart';
import 'model_options.dart';

String normalizeModelName(String model) {
  final m = model.toLowerCase().trim();
  if (m == 'sonnet 5' ||
      m == 'sonnet-5' ||
      m == 'claude 5' ||
      m == 'claude-5' ||
      m == 'sonnet') {
    return 'claude-sonnet-5';
  }
  if (m == 'sonnet 4.6' ||
      m == 'sonnet-4.6' ||
      m == 'sonnet-4-6' ||
      m == 'claude 4.6' ||
      m == 'claude-4.6') {
    return 'claude-sonnet-4-6';
  }
  if (m == 'flash' || m == 'gemini flash') {
    return AiModelCatalogService.defaultGeminiModel;
  }
  if (m == 'pro' || m == 'gemini pro') {
    return 'gemini-2.5-pro';
  }
  return model.trim();
}

ModelSwitchOption? selectModelOption(
    String input, List<ModelSwitchOption> options, AiConfigModel? aiConfig) {
  final raw = input.trim();
  if (raw.isEmpty) return null;
  final clean = raw.toLowerCase();

  // 1. Direct index lookup [1..N]
  final index = int.tryParse(clean);
  if (index != null && index >= 1 && index <= options.length) {
    return options[index - 1];
  }

  // 2. Explicit command "ollama <model>" or "local <model>"
  if (clean.startsWith('ollama ') || clean.startsWith('local ')) {
    final targetModel = raw.substring(raw.indexOf(' ') + 1).trim();
    if (targetModel.isNotEmpty) {
      final ollamaCfg = aiConfig?.providers['ollama'];
      final baseUrl = OllamaUrlHelper.normalize(ollamaCfg?.baseUrl);
      return ModelSwitchOption(
        label: '$targetModel (ollama)',
        provider: 'ollama',
        model: targetModel,
        baseUrl: baseUrl,
        isLocal: true,
      );
    }
  }

  // 3. Quick alias normalization for known models (e.g. "sonnet 5" -> "claude-sonnet-5")
  final resolvedModel = normalizeModelName(clean);
  final isModelAlias = resolvedModel != clean;
  final modelToSearch = isModelAlias ? resolvedModel : clean;

  // 4. Raw provider typed by user (e.g. "claude", "anthropic", "openai", "chat_gpt", "gemini", "ollama")
  if (!isModelAlias) {
    final matchedProvider = normalizeAiProvider(clean);
    if (matchedProvider != null) {
      for (final opt in options) {
        if (opt.provider == matchedProvider) {
          return opt;
        }
      }
      final provCfg = aiConfig?.providers[matchedProvider];
      final modelName =
          provCfg?.defaultModel ?? defaultAiModelFor(matchedProvider);
      final key = provCfg?.apiKey ?? resolveAiEnvApiKey(matchedProvider);
      final baseUrl = provCfg?.baseUrl;
      final isLocal = matchedProvider == 'ollama' ||
          matchedProvider == 'local_ai' ||
          (baseUrl != null &&
              baseUrl.isNotEmpty &&
              LanAiHelper.isLocalOrLan(baseUrl));

      return ModelSwitchOption(
        label: '$modelName ($matchedProvider)',
        provider: matchedProvider,
        model: modelName,
        apiKey: key,
        baseUrl: baseUrl,
        isLocal: isLocal,
      );
    }
  }

  // 5. Exact match or alias lookup among existing options
  for (final opt in options) {
    if (opt.model.toLowerCase() == modelToSearch ||
        opt.aliases.any((a) => a.toLowerCase() == clean)) {
      return opt;
    }
  }

  // 6. Dynamic model typed by user (e.g. "qwen2.5-coder:7b", "claude-sonnet-5", "deepseek-r1:8b")
  final inferred = inferAiProviderFromModel(modelToSearch);
  if (inferred != null) {
    final provCfg = aiConfig?.providers[inferred];
    final key = provCfg?.apiKey ?? resolveAiEnvApiKey(inferred);
    final baseUrl = provCfg?.baseUrl;
    final isLocal = inferred == 'ollama' ||
        inferred == 'local_ai' ||
        (baseUrl != null &&
            baseUrl.isNotEmpty &&
            LanAiHelper.isLocalOrLan(baseUrl));

    return ModelSwitchOption(
      label: '$raw ($inferred)',
      provider: inferred,
      model: raw,
      apiKey: key,
      baseUrl: baseUrl,
      isLocal: isLocal,
    );
  }

  // 7. If model lacks standard prefix, check if it exists in any configured provider
  if (aiConfig?.providers != null) {
    for (final entry in aiConfig!.providers.entries) {
      if (entry.value.defaultModel.toLowerCase() == clean ||
          entry.value.knownModels.any((m) => m.toLowerCase() == clean)) {
        final prov = entry.key;
        final key = entry.value.apiKey ?? resolveAiEnvApiKey(prov);
        final baseUrl = entry.value.baseUrl;
        final isLocal = prov == 'ollama' ||
            prov == 'local_ai' ||
            (baseUrl != null &&
                baseUrl.isNotEmpty &&
                LanAiHelper.isLocalOrLan(baseUrl));

        return ModelSwitchOption(
          label: '$raw ($prov)',
          provider: prov,
          model: raw,
          apiKey: key,
          baseUrl: baseUrl,
          isLocal: isLocal,
        );
      }
    }
  }

  // 8. If still not found and looks like an Ollama model (e.g. "qwen2.5-coder:7b", "my-model:latest")
  if (raw.contains(':') || raw.contains('-') || raw.contains('.')) {
    final ollamaCfg = aiConfig?.providers['ollama'];
    return ModelSwitchOption(
      label: '$raw (ollama)',
      provider: 'ollama',
      model: raw,
      baseUrl: OllamaUrlHelper.normalize(ollamaCfg?.baseUrl),
      isLocal: true,
    );
  }

  return null;
}
