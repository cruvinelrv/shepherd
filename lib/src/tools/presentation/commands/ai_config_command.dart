import 'dart:io';
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
        activeModel: 'gemini-2.5-flash',
      );

  // Modo flag rápida: --sync
  if (args.contains('--sync') || args.contains('-s')) {
    print('${AnsiColors.cyan}🔄 Sincronizando catálogo de modelos online...${AnsiColors.reset}');
    config = await _syncAllModels(config, catalogService);
    service.save(config);
    print('${AnsiColors.green}✅ Catálogo sincronizado com sucesso!${AnsiColors.reset}');
    return;
  }

  while (true) {
    print('\n${AnsiColors.bold}🤖 Shepherd AI — Configuração Multi-Modelos${AnsiColors.reset}');
    print('────────────────────────────────────────────────────────');
    print('Provedor Ativo: ${AnsiColors.brightGreen}${config.activeProvider}${AnsiColors.reset} | Modelo: ${AnsiColors.brightCyan}${config.activeModel}${AnsiColors.reset}');
    print('────────────────────────────────────────────────────────');

    final providerDefs = [
      {'id': 'gemini', 'name': 'Google Gemini'},
      {'id': 'openai', 'name': 'OpenAI (GPT/o-series)'},
      {'id': 'anthropic', 'name': 'Anthropic (Claude)'},
      {'id': 'ollama', 'name': 'Ollama (Local / Offline)'},
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
      } else if (pConfig != null && pConfig.apiKey != null && pConfig.apiKey!.isNotEmpty) {
        status = '${AnsiColors.green}[Configurado: ${_maskApiKey(pConfig.apiKey!)}]${AnsiColors.reset}';
      } else {
        status = '${AnsiColors.yellow}[Não configurado]${AnsiColors.reset}';
      }

      final activeBadge = isActive ? ' ${AnsiColors.brightGreen}★ (Ativo)${AnsiColors.reset}' : '';
      print('  [${i + 1}] $pName $status$activeBadge');
    }

    print('  ──────────────────────────────────────────────────────');
    print('  [S] 🔄 Sincronizar catálogo de modelos de todos os provedores');
    print('  [0] Salvar e Sair');

    stdout.write('\nEscolha uma opção [1-4, S, 0]: ');
    final input = stdin.readLineSync()?.trim().toLowerCase();

    if (input == null || input == '0' || input == 'sair' || input == 'q') {
      service.save(config);
      print('\n${AnsiColors.brightGreen}✅ Configurações salvas em .shepherd/ai_config.yaml${AnsiColors.reset}\n');
      break;
    }

    if (input == 's') {
      print('\n${AnsiColors.cyan}🔄 Sincronizando catálogo de modelos online...${AnsiColors.reset}');
      config = await _syncAllModels(config, catalogService);
      service.save(config);
      print('${AnsiColors.brightGreen}✅ Modelos sincronizados e salvos!${AnsiColors.reset}');
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
      print('${AnsiColors.red}Opção inválida.${AnsiColors.reset}');
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
  print('\n${AnsiColors.bold}⚙️  Configurando $providerName${AnsiColors.reset}');
  final current = config.providers[providerId];

  String? apiKey = current?.apiKey;
  String? baseUrl = current?.baseUrl;

  if (providerId == 'ollama') {
    final defaultUrl = OllamaUrlHelper.normalize(baseUrl);
    stdout.write('URL do Ollama (localhost ou IP/hostname da rede, ex: http://192.168.1.50:11434) [$defaultUrl]: ');
    final urlInput = stdin.readLineSync()?.trim();
    baseUrl = OllamaUrlHelper.normalize(urlInput == null || urlInput.isEmpty ? defaultUrl : urlInput);
  } else {
    stdout.write(
      current?.apiKey != null && current!.apiKey!.isNotEmpty
          ? 'API Key (Enter para manter ${_maskApiKey(current.apiKey!)}): '
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
  var selectedModel = current?.defaultModel ?? (models.isNotEmpty ? models.first : 'default');

  while (true) {
    print('\nSelecione o modelo padrão para $providerName:');
    for (var i = 0; i < models.length; i++) {
      final isCurrent = models[i] == selectedModel;
      final badge = isCurrent ? ' ${AnsiColors.brightGreen}(Selecionado)${AnsiColors.reset}' : '';
      print('  [${i + 1}] ${models[i]}$badge');
    }
    print('  ──────────────────────────────────────────────────────');
    print('  [+] Adicionar novo modelo manualmente');
    print('  [R] 🔄 Buscar modelos disponíveis online nesta conta/servidor');
    print('  [C] Concluir seleção de modelo');

    stdout.write('\nEscolha uma opção [1-${models.length}, +, R, C]: ');
    final choice = stdin.readLineSync()?.trim().toLowerCase();

    if (choice == null || choice == 'c' || choice.isEmpty) {
      break;
    }

    if (choice == '+') {
      stdout.write('\nDigite o identificador exato do modelo (ex: gemini-2.5-flash-thinking): ');
      final customModel = stdin.readLineSync()?.trim();
      if (customModel != null && customModel.isNotEmpty) {
        if (!models.contains(customModel)) {
          models.add(customModel);
        }
        selectedModel = customModel;
        print('${AnsiColors.green}Modelo "$customModel" adicionado e selecionado!${AnsiColors.reset}');
      }
      continue;
    }

    if (choice == 'r') {
      print('\n${AnsiColors.cyan}Consultando modelos disponíveis via API...${AnsiColors.reset}');
      final fetched = await catalogService.fetchOnlineModels(
        providerId: providerId,
        apiKey: apiKey,
        baseUrl: baseUrl,
      );
      if (fetched.isNotEmpty) {
        print('${AnsiColors.green}Encontrados ${fetched.length} modelos online!${AnsiColors.reset}');
        for (final m in fetched) {
          if (!models.contains(m)) models.add(m);
        }
      } else {
        print('${AnsiColors.yellow}Nenhum modelo retornado ou não foi possível conectar.${AnsiColors.reset}');
      }
      continue;
    }

    final mIdx = int.tryParse(choice);
    if (mIdx != null && mIdx >= 1 && mIdx <= models.length) {
      selectedModel = models[mIdx - 1];
      print('${AnsiColors.green}Modelo "$selectedModel" selecionado.${AnsiColors.reset}');
      break;
    }
  }

  stdout.write('\nDeseja definir $providerName ($selectedModel) como o provedor ativo do Shepherd? [S/n]: ');
  final makeActive = stdin.readLineSync()?.trim().toLowerCase();
  final shouldBeActive = makeActive == null || makeActive.isEmpty || makeActive == 's' || makeActive == 'sim' || makeActive == 'y';

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
  print('${AnsiColors.brightGreen}✅ Provedor $providerName configurado com sucesso!${AnsiColors.reset}');
  return newConfig;
}

Future<AiConfigModel> _syncAllModels(
  AiConfigModel config,
  AiModelCatalogService catalogService,
) async {
  final updatedProviders = Map<String, AiProviderConfigEntity>.from(config.providers);

  for (final pId in ['gemini', 'openai', 'anthropic', 'ollama']) {
    final pConfig = config.providers[pId];
    final fetched = await catalogService.fetchOnlineModels(
      providerId: pId,
      apiKey: pConfig?.apiKey,
      baseUrl: pConfig?.baseUrl,
    );

    final currentKnown = AiModelCatalogService.getKnownModels(pId, userModels: pConfig?.knownModels);
    final merged = <String>{...currentKnown, ...fetched}.toList();

    updatedProviders[pId] = AiProviderConfigModel(
      id: pId,
      apiKey: pConfig?.apiKey,
      baseUrl: pConfig?.baseUrl,
      defaultModel: pConfig?.defaultModel ?? (merged.isNotEmpty ? merged.first : 'default'),
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
