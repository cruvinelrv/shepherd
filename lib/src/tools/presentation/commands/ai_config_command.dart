import 'dart:io';

import '../../../i18n/i18n.dart';
import '../../domain/services/ai_config_service.dart';
import '../../domain/services/ai_model_catalog_service.dart';
import '../../domain/services/ollama_url_helper.dart';
import '../../../utils/ansi_colors.dart';

Future<void> runAiConfigCommand([List<String> args = const []]) async {
  final service = AiConfigService();
  final catalogService = AiModelCatalogService();
  var config = service.load() ??
      const AiConfigModel(
        activeProvider: 'gemini',
        activeModel: AiModelCatalogService.defaultGeminiModel,
      );

  // Quick flag mode: --sync
  if (args.contains('--sync') || args.contains('-s')) {
    print('${AnsiColors.cyan}${t('cfg.syncing')}${AnsiColors.reset}');
    config = await _syncAllModels(config, catalogService);
    service.save(config);
    print('${AnsiColors.green}${t('cfg.synced')}${AnsiColors.reset}');
    return;
  }

  while (true) {
    print('\n${AnsiColors.bold}${t('cfg.title')}${AnsiColors.reset}');
    print('────────────────────────────────────────────────────────');
    print(t('cfg.active_line', {
      'provider':
          '${AnsiColors.brightGreen}${config.activeProvider}${AnsiColors.reset}',
      'model':
          '${AnsiColors.brightCyan}${config.activeModel}${AnsiColors.reset}'
    }));
    print('────────────────────────────────────────────────────────');

    final providerDefs = [
      {'id': 'gemini', 'name': 'Google Gemini'},
      {'id': 'openai', 'name': 'OpenAI (GPT/o-series)'},
      {'id': 'anthropic', 'name': 'Anthropic (Claude)'},
      {'id': 'opencode', 'name': t('cfg.p_opencode')},
      {'id': 'ollama', 'name': t('dn.ollama')},
      {'id': 'local_ai', 'name': t('cfg.p_local_ai')},
    ];

    for (var i = 0; i < providerDefs.length; i++) {
      final pId = providerDefs[i]['id']!;
      final pName = providerDefs[i]['name']!;
      final pConfig = config.providers[pId];
      final isActive = config.activeProvider.toLowerCase() == pId;

      String status;
      if (pId == 'ollama') {
        final url = pConfig?.baseUrl ?? 'http://localhost:11434';
        status = '${AnsiColors.green}[$url]${AnsiColors.reset}';
      } else if (pId == 'local_ai') {
        final url = pConfig?.baseUrl ?? 'http://localhost:1234/v1';
        status = pConfig != null
            ? '${AnsiColors.green}[$url]${AnsiColors.reset}'
            : '${AnsiColors.yellow}${t('cfg.not_configured')}${AnsiColors.reset}';
      } else if (pId == 'opencode') {
        final hasKey = pConfig != null &&
            pConfig.apiKey != null &&
            pConfig.apiKey!.isNotEmpty;
        status = hasKey
            ? '${AnsiColors.green}${t('cfg.configured', {
                    'key': _maskApiKey(pConfig.apiKey!)
                  })}${AnsiColors.reset}'
            : '${AnsiColors.yellow}${t('cfg.not_configured')}${AnsiColors.reset}';
      } else if (pConfig != null &&
          pConfig.apiKey != null &&
          pConfig.apiKey!.isNotEmpty) {
        status = '${AnsiColors.green}${t('cfg.configured', {
              'key': _maskApiKey(pConfig.apiKey!)
            })}${AnsiColors.reset}';
      } else {
        status =
            '${AnsiColors.yellow}${t('cfg.not_configured')}${AnsiColors.reset}';
      }

      final activeBadge = isActive
          ? ' ${AnsiColors.brightGreen}${t('models.active')}${AnsiColors.reset}'
          : '';
      print('  [${i + 1}] $pName $status$activeBadge');
    }

    print('  ──────────────────────────────────────────────────────');
    print(t('cfg.menu_profiles'));
    print(t('cfg.menu_sync'));
    print(t('cfg.menu_save'));

    stdout.write(t('cfg.choose_main', {'n': providerDefs.length}));
    final input = stdin.readLineSync()?.trim().toLowerCase();

    if (input == null ||
        const {'0', 'q', 'exit', 'sair', 'salir'}.contains(input)) {
      service.save(config);
      print('${AnsiColors.brightGreen}${t('cfg.saved')}${AnsiColors.reset}');
      break;
    }

    if (input == 'p') {
      config = await _configureModelProfiles(
        config: config,
        service: service,
      );
      continue;
    }

    if (input == 's') {
      print('\n${AnsiColors.cyan}${t('cfg.syncing')}${AnsiColors.reset}');
      config = await _syncAllModels(config, catalogService);
      service.save(config);
      print(
          '${AnsiColors.brightGreen}${t('cfg.models_synced')}${AnsiColors.reset}');
      continue;
    }

    final index = int.tryParse(input);
    if (index != null && index >= 1 && index <= providerDefs.length) {
      final selected = providerDefs[index - 1];
      final pId = selected['id']!;
      final pName = selected['name']!;

      config = await _configureProvider(
        config: config,
        providerId: pId,
        providerName: pName,
        catalogService: catalogService,
        service: service,
      );
    } else {
      print('${AnsiColors.red}${t('cfg.invalid')}${AnsiColors.reset}');
    }
  }
}

Future<AiConfigModel> _configureProvider({
  required AiConfigModel config,
  required String providerId,
  required String providerName,
  required AiModelCatalogService catalogService,
  required AiConfigService service,
}) async {
  print('${AnsiColors.bold}${t('cfg.setup', {
        'name': providerName
      })}${AnsiColors.reset}');
  final current = config.providers[providerId];

  String? apiKey = current?.apiKey;
  String? baseUrl = current?.baseUrl;

  if (providerId == 'opencode') {
    final defaultUrl = LanAiHelper.normalize(baseUrl,
        defaultUrl: 'https://opencode.ai/zen/v1');
    stdout.write(t('cfg.opencode_url', {'url': defaultUrl}));
    final urlInput = stdin.readLineSync()?.trim();
    baseUrl = LanAiHelper.normalize(
      urlInput == null || urlInput.isEmpty ? defaultUrl : urlInput,
      defaultUrl: 'https://opencode.ai/zen/v1',
    );
    stdout.write(
      current?.apiKey != null && current!.apiKey!.isNotEmpty
          ? t('cfg.key_keep', {'key': _maskApiKey(current.apiKey!)})
          : t('cfg.key_opencode'),
    );
    final keyInput = stdin.readLineSync()?.trim();
    if (keyInput != null && keyInput.isNotEmpty) {
      apiKey = keyInput;
    }
  } else if (providerId == 'ollama' || providerId == 'local_ai') {
    final isOllama = providerId == 'ollama';
    final defaultUrl = isOllama
        ? OllamaUrlHelper.normalize(baseUrl)
        : LanAiHelper.normalize(baseUrl,
            defaultUrl: 'http://localhost:1234/v1');

    print(t('cfg.where_runs', {'name': providerName}));
    print(t('cfg.where_here'));
    print(t('cfg.where_lan'));
    stdout.write(t('cfg.where_choose', {'url': defaultUrl}));
    final locChoice = stdin.readLineSync()?.trim();

    if (locChoice == '1') {
      baseUrl =
          isOllama ? 'http://localhost:11434' : 'http://localhost:1234/v1';
      print('${AnsiColors.green}${t('cfg.set_localhost', {
            'url': baseUrl
          })}${AnsiColors.reset}');
    } else if (locChoice == '2') {
      final portHint = isOllama ? '11434' : '1234/v1';
      stdout.write(t('cfg.ask_host', {'port': portHint, 'url': defaultUrl}));
      final urlInput = stdin.readLineSync()?.trim();
      baseUrl = LanAiHelper.normalize(
        urlInput == null || urlInput.isEmpty ? defaultUrl : urlInput,
        defaultUrl: defaultUrl,
      );
    } else {
      baseUrl = defaultUrl;
    }

    if (providerId == 'local_ai') {
      stdout.write(
        current?.apiKey != null && current!.apiKey!.isNotEmpty
            ? t('cfg.key_local_keep', {'key': _maskApiKey(current.apiKey!)})
            : t('cfg.key_local_new'),
      );
      final keyInput = stdin.readLineSync()?.trim();
      if (keyInput != null && keyInput.isNotEmpty) {
        apiKey = keyInput;
      }
    }
  } else {
    stdout.write(
      current?.apiKey != null && current!.apiKey!.isNotEmpty
          ? t('cfg.key_keep', {'key': _maskApiKey(current.apiKey!)})
          : 'API Key: ',
    );

    bool echoDisabled = false;
    try {
      stdin.echoMode = false;
      echoDisabled = true;
    } catch (_) {}

    final keyInput = stdin.readLineSync()?.trim();

    if (echoDisabled) {
      try {
        stdin.echoMode = true;
      } catch (_) {}
    }
    print('');

    if (keyInput != null && keyInput.isNotEmpty) {
      apiKey = keyInput;
    }
  }

  // Model Selection Loop
  var models = AiModelCatalogService.getKnownModels(
    providerId,
    userModels: current?.knownModels,
  );
  var selectedModel =
      current?.defaultModel ?? (models.isNotEmpty ? models.first : 'default');

  while (true) {
    print(t('cfg.pick_default', {'name': providerName}));
    for (var i = 0; i < models.length; i++) {
      final isCurrent = models[i] == selectedModel;
      final badge = isCurrent
          ? ' ${AnsiColors.brightGreen}${t('cfg.selected_badge')}${AnsiColors.reset}'
          : '';
      print('  [${i + 1}] ${models[i]}$badge');
    }
    print('  ──────────────────────────────────────────────────────');
    print(t('cfg.add_manual'));
    print(t('cfg.fetch_online'));
    print(t('cfg.finish'));

    stdout.write(t('cfg.choose_model_menu', {'n': models.length}));
    final choice = stdin.readLineSync()?.trim().toLowerCase();

    if (choice == null || choice == 'c' || choice.isEmpty) {
      break;
    }

    if (choice == '+') {
      stdout.write(t('cfg.ask_model_id'));
      final customModel = stdin.readLineSync()?.trim();
      if (customModel != null && customModel.isNotEmpty) {
        if (!models.contains(customModel)) {
          models.add(customModel);
        }
        selectedModel = customModel;
        print('${AnsiColors.green}${t('cfg.model_added', {
              'model': customModel
            })}${AnsiColors.reset}');
      }
      continue;
    }

    if (choice == 'r') {
      print('${AnsiColors.cyan}${t('cfg.querying')}${AnsiColors.reset}');
      final fetched = await catalogService.fetchOnlineModels(
        providerId: providerId,
        apiKey: apiKey,
        baseUrl: baseUrl,
      );
      if (fetched.isNotEmpty) {
        print('${AnsiColors.green}${t('cfg.found_online', {
              'n': fetched.length
            })}${AnsiColors.reset}');
        for (final m in fetched) {
          if (!models.contains(m)) models.add(m);
        }
      } else {
        print('${AnsiColors.yellow}${t('cfg.none_online')}${AnsiColors.reset}');
      }
      continue;
    }

    final mIdx = int.tryParse(choice);
    if (mIdx != null && mIdx >= 1 && mIdx <= models.length) {
      selectedModel = models[mIdx - 1];
      print('${AnsiColors.green}${t('cfg.model_selected', {
            'model': selectedModel
          })}${AnsiColors.reset}');
      break;
    }
  }

  stdout.write(
      t('cfg.make_active', {'name': providerName, 'model': selectedModel}));
  final makeActive = stdin.readLineSync()?.trim().toLowerCase();
  final shouldBeActive = makeActive == null ||
      makeActive.isEmpty ||
      const {'y', 'yes', 's', 'sim', 'si', 's\u00ed'}.contains(makeActive);

  final updatedProvider = AiProviderConfigModel(
    id: providerId,
    apiKey: apiKey,
    baseUrl: baseUrl,
    defaultModel: selectedModel,
    knownModels: models,
  );

  final updatedMap = Map<String, AiProviderConfigEntity>.from(config.providers);
  updatedMap[providerId] = updatedProvider;

  final newConfig = AiConfigModel(
    activeProvider: shouldBeActive ? providerId : config.activeProvider,
    activeModel: shouldBeActive ? selectedModel : config.activeModel,
    providers: updatedMap,
  );

  service.save(newConfig);
  print('${AnsiColors.brightGreen}${t('cfg.provider_done', {
        'name': providerName
      })}${AnsiColors.reset}');
  return newConfig;
}

Future<AiConfigModel> _syncAllModels(
  AiConfigModel config,
  AiModelCatalogService catalogService,
) async {
  final updatedProviders =
      Map<String, AiProviderConfigEntity>.from(config.providers);

  for (final pId in [
    'gemini',
    'openai',
    'anthropic',
    'opencode',
    'ollama',
    'local_ai'
  ]) {
    final pConfig = config.providers[pId];
    final fetched = await catalogService.fetchOnlineModels(
      providerId: pId,
      apiKey: pConfig?.apiKey,
      baseUrl: pConfig?.baseUrl,
    );

    final currentKnown = AiModelCatalogService.getKnownModels(pId,
        userModels: pConfig?.knownModels);
    final merged = <String>{...currentKnown, ...fetched}.toList();

    updatedProviders[pId] = AiProviderConfigModel(
      id: pId,
      apiKey: pConfig?.apiKey,
      baseUrl: pConfig?.baseUrl,
      defaultModel: pConfig?.defaultModel ??
          (merged.isNotEmpty ? merged.first : 'default'),
      knownModels: merged,
    );
  }

  return AiConfigModel(
    activeProvider: config.activeProvider,
    activeModel: config.activeModel,
    providers: updatedProviders,
  );
}

String _maskApiKey(String apiKey) {
  if (apiKey.length <= 4) return '****';
  return '${'*' * (apiKey.length - 4)}${apiKey.substring(apiKey.length - 4)}';
}

Future<AiConfigModel> _configureModelProfiles({
  required AiConfigModel config,
  required AiConfigService service,
}) async {
  while (true) {
    final adv = config.resolveProfileSlot('advanced');
    final med = config.resolveProfileSlot('medium');
    final loc = config.resolveProfileSlot('local');

    String row(String label, dynamic slot, String usage, {String extra = ''}) {
      return '$label ${AnsiColors.brightCyan}${slot.provider} (${slot.model})${AnsiColors.reset}$extra\n'
          '      ${AnsiColors.gray}${t(usage)}${AnsiColors.reset}';
    }

    print('${AnsiColors.bold}${t('prof.title')}${AnsiColors.reset}');
    print('────────────────────────────────────────────────────────');
    print(row(t('prof.advanced'), adv, 'prof.use_advanced'));
    print(row(t('prof.medium'), med, 'prof.use_medium',
        extra: config.activeProfile == 'medium'
            ? ' ${t('prof.default_star')}'
            : ''));
    print(row(t('prof.local'), loc, 'prof.use_local'));
    print('  ──────────────────────────────────────────────────────');
    print(t('prof.set_default', {'profile': config.activeProfile}));
    print(t('prof.back'));

    stdout.write(t('prof.pick_option'));
    final opt = stdin.readLineSync()?.trim().toLowerCase();

    if (opt == null ||
        opt == '0' ||
        opt == 'voltar' ||
        opt == 'volver' ||
        opt == 'back' ||
        opt == 'q') {
      break;
    }

    if (opt == 'd') {
      stdout.write(t('prof.pick_default'));
      final dChoice = stdin.readLineSync()?.trim();
      String newDef = config.activeProfile;
      if (dChoice == '1' ||
          dChoice == 'advanced' ||
          dChoice == 'avancado' ||
          dChoice == 'avanzado') {
        newDef = 'advanced';
      } else if (dChoice == '2' || dChoice == 'medium' || dChoice == 'medio') {
        newDef = 'medium';
      } else if (dChoice == '3' || dChoice == 'local') {
        newDef = 'local';
      }

      final activeSlot = config.resolveProfileSlot(newDef);
      config = AiConfigModel(
        activeProvider: activeSlot.provider,
        activeModel: activeSlot.model,
        activeProfile: newDef,
        advanced: config.advanced,
        medium: config.medium,
        local: config.local,
        providers: config.providers,
      );
      service.save(config);
      print('${AnsiColors.brightGreen}${t('prof.default_changed', {
            'profile': newDef
          })}${AnsiColors.reset}');
      continue;
    }

    if (opt == '1' || opt == '2' || opt == '3') {
      final slotKey =
          opt == '1' ? 'advanced' : (opt == '2' ? 'medium' : 'local');
      final slotName =
          opt == '1' ? 'Advanced' : (opt == '2' ? 'Medium' : 'Local');

      print(t('prof.pick_provider', {'slot': slotName}));
      final pList = <String>[];
      for (final p in [
        'gemini',
        'openai',
        'anthropic',
        'opencode',
        'ollama',
        'local_ai'
      ]) {
        if (!pList.contains(p)) pList.add(p);
      }

      for (var i = 0; i < pList.length; i++) {
        print('  [${i + 1}] ${pList[i]}');
      }
      stdout.write(t('prof.pick_provider_n', {'n': pList.length}));
      final pIdx = int.tryParse(stdin.readLineSync()?.trim() ?? '');
      if (pIdx == null || pIdx < 1 || pIdx > pList.length) continue;

      final chosenProvider = pList[pIdx - 1];
      var currentModels = AiModelCatalogService.getKnownModels(
        chosenProvider,
        userModels: config.providers[chosenProvider]?.knownModels,
      );
      try {
        final online = await AiModelCatalogService()
            .fetchOnlineModels(
              providerId: chosenProvider,
              apiKey: config.providers[chosenProvider]?.apiKey,
              baseUrl: config.providers[chosenProvider]?.baseUrl,
            )
            .timeout(const Duration(milliseconds: 800));
        if (online.isNotEmpty) {
          final set = <String>{...online, ...currentModels};
          currentModels = set.toList();
        }
      } catch (_) {}

      print(
          t('prof.pick_model', {'slot': slotName, 'provider': chosenProvider}));
      for (var i = 0; i < currentModels.length; i++) {
        print('  [${i + 1}] ${currentModels[i]}');
      }
      stdout.write(t('prof.pick_model_n', {'n': currentModels.length}));
      final mInput = stdin.readLineSync()?.trim() ?? '';
      final mIdx = int.tryParse(mInput);
      final chosenModel =
          (mIdx != null && mIdx >= 1 && mIdx <= currentModels.length)
              ? currentModels[mIdx - 1]
              : (mInput.isNotEmpty ? mInput : currentModels.first);

      final newSlot =
          AiModelSlotModel(provider: chosenProvider, model: chosenModel);
      config = AiConfigModel(
        activeProvider: config.activeProfile == slotKey
            ? chosenProvider
            : config.activeProvider,
        activeModel:
            config.activeProfile == slotKey ? chosenModel : config.activeModel,
        activeProfile: config.activeProfile,
        advanced: slotKey == 'advanced' ? newSlot : config.advanced,
        medium: slotKey == 'medium' ? newSlot : config.medium,
        local: slotKey == 'local' ? newSlot : config.local,
        providers: config.providers,
      );
      service.save(config);
      print('${AnsiColors.brightGreen}${t('prof.slot_done', {
            'slot': slotName,
            'provider': chosenProvider,
            'model': chosenModel
          })}${AnsiColors.reset}');
    }
  }
  return config;
}
