import 'dart:io';

import '../../../../i18n/i18n.dart';

import '../../../../utils/ansi_colors.dart';
import '../../../domain/services/ai_config_service.dart';
import '../../../domain/services/ai_model_catalog_service.dart';
import '../../../domain/services/ai_settings_resolver.dart';
import '../../../domain/services/ollama_url_helper.dart';
import '../ai_cloud_model_picker.dart';
import 'model_options.dart';

Future<ModelSwitchOption?> promptOllamaModelSelection({
  required AiConfigModel? aiConfig,
  required String currentModel,
}) async {
  var currentCfg = aiConfig;
  var ollamaCfg = currentCfg?.providers['ollama'];
  var localUrl = OllamaUrlHelper.normalize(ollamaCfg?.baseUrl);

  while (true) {
    stdout.write(t('ollama.fetching', {'url': localUrl}));
    List<String> onlineModels = [];
    try {
      onlineModels = await AiModelCatalogService()
          .fetchOnlineModels(providerId: 'ollama', baseUrl: localUrl)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}

    final allOllamaModels = <String>{
      ...onlineModels,
      if (ollamaCfg?.defaultModel != null) ollamaCfg!.defaultModel,
      ...?ollamaCfg?.knownModels,
      ...?AiModelCatalogService.defaultModels['ollama'],
    }.toList();

    if (onlineModels.isNotEmpty) {
      stdout.writeln('${AnsiColors.brightGreen}${t('ollama.detected', {
            'n': onlineModels.length
          })}${AnsiColors.reset}\n');
    } else {
      stdout.writeln('${AnsiColors.brightYellow}${t('ollama.offline', {
            'url': localUrl
          })}${AnsiColors.reset}');
      stdout.writeln(t('ollama.lan_tip',
          {'key': '${AnsiColors.bold}[u]${AnsiColors.reset}'}));
    }

    print('${AnsiColors.bold}${t('ollama.models_title')}${AnsiColors.reset}');
    for (var i = 0; i < allOllamaModels.length; i++) {
      final m = allOllamaModels[i];
      final isCurrent = m == currentModel;
      final check = isCurrent
          ? ' ${AnsiColors.brightGreen}${t('models.active')}${AnsiColors.reset}'
          : '';
      print('  [${i + 1}] $m$check');
    }
    print(t('ollama.change_url', {'url': localUrl}));

    print(
        '────────────────────────────────────────────────────────────────────────');
    stdout.write(t(
        'ollama.choose', {'n': allOllamaModels.length, 'model': currentModel}));
    final input = stdin.readLineSync()?.trim();
    if (input == null || input.isEmpty) {
      return ModelSwitchOption(
        label: '$currentModel (ollama)',
        provider: 'ollama',
        model: currentModel,
        baseUrl: localUrl,
        isLocal: true,
      );
    }

    if (input.toLowerCase() == 'u' ||
        input.toLowerCase() == 'url' ||
        input.toLowerCase() == 'ip') {
      stdout.write(t('ollama.ask_url', {'url': localUrl}));
      final newUrlInput = stdin.readLineSync()?.trim();
      final newUrl = LanAiHelper.normalize(
        newUrlInput == null || newUrlInput.isEmpty ? localUrl : newUrlInput,
        defaultUrl: localUrl,
      );
      localUrl = newUrl;

      if (currentCfg != null) {
        final updatedProviders =
            Map<String, AiProviderConfigEntity>.from(currentCfg.providers);
        final existingProv = updatedProviders['ollama'];
        updatedProviders['ollama'] = AiProviderConfigModel(
          id: 'ollama',
          apiKey: existingProv?.apiKey,
          baseUrl: localUrl,
          defaultModel: existingProv?.defaultModel ?? currentModel,
          knownModels: existingProv?.knownModels ?? [],
        );
        final updated = currentCfg.copyWith(providers: updatedProviders);
        AiConfigService().save(updated);
        currentCfg = updated;
        ollamaCfg = updated.providers['ollama'];
      }
      print('${AnsiColors.brightGreen}${t('ollama.url_updated', {
            'url': localUrl
          })}${AnsiColors.reset}');
      continue;
    }

    final idx = int.tryParse(input);
    String chosenModel;
    if (idx != null && idx >= 1 && idx <= allOllamaModels.length) {
      chosenModel = allOllamaModels[idx - 1];
    } else {
      chosenModel = input;
    }

    return ModelSwitchOption(
      label: '$chosenModel (ollama)',
      provider: 'ollama',
      model: chosenModel,
      baseUrl: localUrl,
      isLocal: true,
    );
  }
}

Future<ModelSwitchOption?> promptOpenCodeModelSelection({
  required AiConfigModel? aiConfig,
  required String currentModel,
}) async {
  var currentCfg = aiConfig;
  var openCodeCfg = currentCfg?.providers['opencode'];
  var apiKey = openCodeCfg?.apiKey ?? resolveAiEnvApiKey('opencode');
  final baseUrl = openCodeCfg?.baseUrl ?? 'https://opencode.ai/zen/v1';

  if (apiKey == null || apiKey.isEmpty) {
    stdout.writeln(
        '\n🔑 ${AnsiColors.bold}${t('opencode.setup_title')}${AnsiColors.reset}');
    stdout.writeln(t('opencode.intro'));
    stdout.writeln(t('opencode.get_key'));
    stdout.write(t('opencode.ask_key'));
    final keyInput = stdin.readLineSync()?.trim();
    if (keyInput == null || keyInput.isEmpty) {
      print(t('opencode.cancelled'));
      return null;
    }
    apiKey = keyInput;

    if (currentCfg != null) {
      final updatedProviders =
          Map<String, AiProviderConfigEntity>.from(currentCfg.providers);
      final existingProv = updatedProviders['opencode'];
      updatedProviders['opencode'] = AiProviderConfigModel(
        id: 'opencode',
        apiKey: apiKey,
        baseUrl: baseUrl,
        defaultModel: existingProv?.defaultModel ?? 'qwen3.8-max',
        knownModels: existingProv?.knownModels ??
            AiModelCatalogService.defaultModels['opencode'] ??
            [],
      );
      final updated = currentCfg.copyWith(providers: updatedProviders);
      AiConfigService().save(updated);
      currentCfg = updated;
      openCodeCfg = updated.providers['opencode'];
    }
    print(
        '${AnsiColors.brightGreen}${t('opencode.key_saved').trimRight()}${AnsiColors.reset}\n');
  }

  stdout.write(t('opencode.fetching', {'url': baseUrl}));
  List<String> onlineModels = [];
  try {
    onlineModels = await AiModelCatalogService()
        .fetchOnlineModels(
            providerId: 'opencode', apiKey: apiKey, baseUrl: baseUrl)
        .timeout(const Duration(seconds: 3));
  } catch (_) {}

  final allModels = <String>{
    ...onlineModels,
    if (openCodeCfg?.defaultModel != null) openCodeCfg!.defaultModel,
    ...?openCodeCfg?.knownModels,
    ...?AiModelCatalogService.defaultModels['opencode'],
  }.toList();

  if (onlineModels.isNotEmpty) {
    stdout.writeln('${AnsiColors.brightGreen}${t('opencode.n_models', {
          'n': onlineModels.length
        }).trimRight()}${AnsiColors.reset}\n');
  } else {
    stdout.writeln(
        '${AnsiColors.gray}${t('opencode.default_catalog').trimRight()}${AnsiColors.reset}\n');
  }

  print('${AnsiColors.bold}${t('opencode.models_title')}${AnsiColors.reset}');
  for (var i = 0; i < allModels.length; i++) {
    final m = allModels[i];
    final isCurrent = m == currentModel;
    final check = isCurrent
        ? ' ${AnsiColors.brightGreen}${t('models.active')}${AnsiColors.reset}'
        : '';
    print('  [${i + 1}] $m$check');
  }
  print(t('opencode.update_key'));
  print(t('opencode.type_model'));

  print(
      '────────────────────────────────────────────────────────────────────────');
  stdout.write(
      t('opencode.choose', {'n': allModels.length, 'model': currentModel}));
  final input = stdin.readLineSync()?.trim();
  if (input == null || input.isEmpty) {
    return ModelSwitchOption(
      label: '$currentModel (opencode)',
      provider: 'opencode',
      model: currentModel,
      apiKey: apiKey,
      baseUrl: baseUrl,
      isLocal: false,
    );
  }

  if (input.toLowerCase() == 'k' || input.toLowerCase() == 'key') {
    stdout.write(t('opencode.new_key'));
    final newKey = stdin.readLineSync()?.trim();
    if (newKey != null && newKey.isNotEmpty) {
      apiKey = newKey;
      if (currentCfg != null) {
        final updatedProviders =
            Map<String, AiProviderConfigEntity>.from(currentCfg.providers);
        final existingProv = updatedProviders['opencode'];
        updatedProviders['opencode'] = AiProviderConfigModel(
          id: 'opencode',
          apiKey: apiKey,
          baseUrl: baseUrl,
          defaultModel: existingProv?.defaultModel ?? currentModel,
          knownModels: existingProv?.knownModels ?? allModels,
        );
        final updated = currentCfg.copyWith(providers: updatedProviders);
        AiConfigService().save(updated);
      }
      print(
          '${AnsiColors.brightGreen}${t('opencode.key_updated').trimRight()}${AnsiColors.reset}\n');
    }
  }

  String chosenModel;
  if (input.toLowerCase() == 'm' || input.toLowerCase() == 'outro') {
    stdout.write(t('opencode.ask_model'));
    final customModel = stdin.readLineSync()?.trim();
    chosenModel = (customModel != null && customModel.isNotEmpty)
        ? customModel
        : currentModel;
  } else {
    final idx = int.tryParse(input);
    if (idx != null && idx >= 1 && idx <= allModels.length) {
      chosenModel = allModels[idx - 1];
    } else {
      chosenModel = input;
    }
  }

  return ModelSwitchOption(
    label: '$chosenModel (opencode)',
    provider: 'opencode',
    model: chosenModel,
    apiKey: apiKey,
    baseUrl: baseUrl,
    isLocal: false,
  );
}

/// Lists the models of a cloud provider (OpenAI, Anthropic or Gemini) and
/// returns the chosen one, keeping the provider's saved key.
Future<ModelSwitchOption?> promptCloudProviderSelection({
  required String providerId,
  required AiConfigModel? aiConfig,
  required List<ModelSwitchOption> options,
  required String activeProvider,
  required String activeModel,
}) async {
  final base = options.firstWhere((o) => o.provider == providerId);
  final label = const {
    'openai': 'OpenAI (ChatGPT)',
    'anthropic': 'Anthropic (Claude)',
    'gemini': 'Google (Gemini)',
  }[providerId]!;
  final model = await promptCloudModelSelection(
    providerId: providerId,
    providerLabel: label,
    apiKey: base.apiKey,
    currentModel: activeProvider == providerId ? activeModel : base.model,
    savedModels: aiConfig?.providers[providerId]?.knownModels ?? const [],
  );
  return ModelSwitchOption(
    label: '$model ($providerId)',
    provider: providerId,
    model: model,
    apiKey: base.apiKey,
    isLocal: false,
  );
}
