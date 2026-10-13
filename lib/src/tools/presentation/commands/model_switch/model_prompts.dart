import 'dart:io';

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
    stdout.write('\n🔍 Buscando modelos disponíveis no Ollama ($localUrl)... ');
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
      stdout.writeln(
          '${AnsiColors.brightGreen}${onlineModels.length} modelo(s) detectado(s)!${AnsiColors.reset}\n');
    } else {
      stdout.writeln(
          '${AnsiColors.brightYellow}Ollama offline ou inacessível em $localUrl.${AnsiColors.reset}');
      stdout.writeln(
          '💡 Está em outra máquina na rede? Digite ${AnsiColors.bold}[u]${AnsiColors.reset} para definir IP/porta.\n');
    }

    print(
        '${AnsiColors.bold}Modelos disponíveis no seu Ollama:${AnsiColors.reset}');
    for (var i = 0; i < allOllamaModels.length; i++) {
      final m = allOllamaModels[i];
      final isCurrent = m == currentModel;
      final check = isCurrent
          ? ' ${AnsiColors.brightGreen}★ (Ativo)${AnsiColors.reset}'
          : '';
      print('  [${i + 1}] $m$check');
    }
    print('  [u] 🌐 Alterar IP / URL do Ollama na rede (atual: $localUrl)');

    print(
        '────────────────────────────────────────────────────────────────────────');
    stdout.write(
        'Escolha um modelo [1-${allOllamaModels.length}], [u] para IP/URL (Enter para manter "$currentModel"): ');
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
      stdout.write(
          '\nDigite o IP ou hostname do Ollama na rede (ex: http://192.168.1.50:11434) [$localUrl]: ');
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
      print(
          '${AnsiColors.brightGreen}✅ Endereço do Ollama atualizado para: $localUrl${AnsiColors.reset}');
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
        '\n🔑 ${AnsiColors.bold}Configuração do OpenCode Zen (opencode.ai)${AnsiColors.reset}');
    stdout.writeln(
        'O OpenCode Zen permite acesso a múltiplos modelos de ponta com uma única chave de API.');
    stdout.writeln(
        'Obtenha sua chave em: https://opencode.ai ou https://opencode.ai/zen\n');
    stdout.write(
        'Digite sua chave de API do OpenCode (ou Enter para cancelar): ');
    final keyInput = stdin.readLineSync()?.trim();
    if (keyInput == null || keyInput.isEmpty) {
      print('ℹ️  Configuração cancelada.\n');
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
        '${AnsiColors.brightGreen}✅ Chave de API do OpenCode salva em .shepherd/ai_config.yaml!${AnsiColors.reset}\n');
  }

  stdout
      .write('🔍 Buscando catálogo de modelos no OpenCode Zen ($baseUrl)... ');
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
    stdout.writeln(
        '${AnsiColors.brightGreen}${onlineModels.length} modelo(s) disponível(is)!${AnsiColors.reset}\n');
  } else {
    stdout.writeln(
        '${AnsiColors.gray}Utilizando catálogo padrão do OpenCode Zen.${AnsiColors.reset}\n');
  }

  print(
      '${AnsiColors.bold}Modelos disponíveis no OpenCode Zen:${AnsiColors.reset}');
  for (var i = 0; i < allModels.length; i++) {
    final m = allModels[i];
    final isCurrent = m == currentModel;
    final check = isCurrent
        ? ' ${AnsiColors.brightGreen}★ (Ativo)${AnsiColors.reset}'
        : '';
    print('  [${i + 1}] $m$check');
  }
  print('  [k] 🔑 Atualizar chave de API do OpenCode');
  print('  [m] ✍️ Digitar manualmente outro nome de modelo');

  print(
      '────────────────────────────────────────────────────────────────────────');
  stdout.write(
      'Escolha uma opção [1-${allModels.length}], [k] chave, [m] outro (Enter para manter "$currentModel"): ');
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
    stdout.write('\nDigite a nova chave de API do OpenCode: ');
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
          '${AnsiColors.brightGreen}✅ Chave de API atualizada com sucesso!${AnsiColors.reset}\n');
    }
  }

  String chosenModel;
  if (input.toLowerCase() == 'm' || input.toLowerCase() == 'outro') {
    stdout.write(
        '\nDigite o ID do modelo no OpenCode (ex: deepseek-v4-pro, qwen3.8-max): ');
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
