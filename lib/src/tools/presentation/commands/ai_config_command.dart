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
      {'id': 'ollama', 'name': 'Ollama (Local / Rede Local)'},
      {'id': 'local_ai', 'name': 'Servidor Local / Rede Local (LM Studio, vLLM, Jan, LocalAI)'},
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
            : '${AnsiColors.yellow}[Não configurado]${AnsiColors.reset}';
      } else if (pConfig != null && pConfig.apiKey != null && pConfig.apiKey!.isNotEmpty) {
        status = '${AnsiColors.green}[Configurado: ${_maskApiKey(pConfig.apiKey!)}]${AnsiColors.reset}';
      } else {
        status = '${AnsiColors.yellow}[Não configurado]${AnsiColors.reset}';
      }

      final activeBadge = isActive ? ' ${AnsiColors.brightGreen}★ (Ativo)${AnsiColors.reset}' : '';
      print('  [${i + 1}] $pName $status$activeBadge');
    }

    print('  ──────────────────────────────────────────────────────');
    print('  [P] 🎯 Perfis de Modelos / Slots (Advanced, Medium, Local)');
    print('  [S] 🔄 Sincronizar catálogo de modelos de todos os provedores');
    print('  [0] Salvar e Sair');

    stdout.write('\nEscolha uma opção [1-${providerDefs.length}, P, S, 0]: ');
    final input = stdin.readLineSync()?.trim().toLowerCase();

    if (input == null || input == '0' || input == 'sair' || input == 'q') {
      service.save(config);
      print('\n${AnsiColors.brightGreen}✅ Configurações salvas em .shepherd/ai_config.yaml${AnsiColors.reset}\n');
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

  if (providerId == 'ollama' || providerId == 'local_ai') {
    final isOllama = providerId == 'ollama';
    final defaultUrl = isOllama
        ? OllamaUrlHelper.normalize(baseUrl)
        : LanAiHelper.normalize(baseUrl, defaultUrl: 'http://localhost:1234/v1');

    print('\nOnde está rodando o motor $providerName?');
    print('  [1] No meu próprio computador (localhost)');
    print('  [2] Em outro computador na rede local (LAN / IP)');
    stdout.write('Escolha [1 ou 2, Enter para manter $defaultUrl]: ');
    final locChoice = stdin.readLineSync()?.trim();

    if (locChoice == '1') {
      baseUrl = isOllama ? 'http://localhost:11434' : 'http://localhost:1234/v1';
      print('${AnsiColors.green}Endereço configurado como localhost: $baseUrl${AnsiColors.reset}');
    } else if (locChoice == '2') {
      final portHint = isOllama ? '11434' : '1234/v1';
      stdout.write('Digite o IP ou hostname da outra máquina (ex: http://192.168.1.50:$portHint) [$defaultUrl]: ');
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
            ? 'API Key (Enter para manter ${_maskApiKey(current.apiKey!)} ou deixe em branco se não requer): '
            : 'API Key (opcional para servidores locais/LAN, pressione Enter para pular): ',
      );
      final keyInput = stdin.readLineSync()?.trim();
      if (keyInput != null && keyInput.isNotEmpty) {
        apiKey = keyInput;
      }
    }
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

  for (final pId in ['gemini', 'openai', 'anthropic', 'ollama', 'local_ai']) {
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

Future<AiConfigModel> _configureModelProfiles({
  required AiConfigModel config,
  required AiConfigService service,
}) async {
  while (true) {
    final adv = config.resolveProfileSlot('advanced');
    final med = config.resolveProfileSlot('medium');
    final loc = config.resolveProfileSlot('local');

    print('\n${AnsiColors.bold}🎯 Perfis de Modelos / Model Slots (EN / PT / ES)${AnsiColors.reset}');
    print('────────────────────────────────────────────────────────');
    print('  [1] 🧠 Advanced / Avançado / Avanzado: ${AnsiColors.brightCyan}${adv.provider} (${adv.model})${AnsiColors.reset}');
    print('      ${AnsiColors.gray}Uso: shepherd ai --advanced "..." ou /advanced no shell${AnsiColors.reset}');
    print('  [2] ⚡ Medium / Médio / Medio:         ${AnsiColors.brightCyan}${med.provider} (${med.model})${AnsiColors.reset} ${config.activeProfile == 'medium' ? '★ (Padrão)' : ''}');
    print('      ${AnsiColors.gray}Uso: shepherd ai --medium "..." ou /medium no shell${AnsiColors.reset}');
    print('  [3] 🏡 Local / Local / Local:          ${AnsiColors.brightCyan}${loc.provider} (${loc.model})${AnsiColors.reset}');
    print('      ${AnsiColors.gray}Uso: shepherd ai --local "..." ou /local no shell (Zero Cost)${AnsiColors.reset}');
    print('  ──────────────────────────────────────────────────────');
    print('  [D] Definir perfil ativo padrão (Atual: ${config.activeProfile})');
    print('  [0] Voltar ao menu principal');

    stdout.write('\nEscolha uma opção [1-3, D, 0]: ');
    final opt = stdin.readLineSync()?.trim().toLowerCase();

    if (opt == null || opt == '0' || opt == 'voltar' || opt == 'q') {
      break;
    }

    if (opt == 'd') {
      stdout.write('Escolha o perfil padrão [1: Advanced, 2: Medium, 3: Local]: ');
      final dChoice = stdin.readLineSync()?.trim();
      String newDef = config.activeProfile;
      if (dChoice == '1' || dChoice == 'advanced' || dChoice == 'avancado' || dChoice == 'avanzado') {
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
      print('${AnsiColors.brightGreen}✅ Perfil padrão alterado para: $newDef!${AnsiColors.reset}');
      continue;
    }

    if (opt == '1' || opt == '2' || opt == '3') {
      final slotKey = opt == '1' ? 'advanced' : (opt == '2' ? 'medium' : 'local');
      final slotName = opt == '1' ? 'Advanced' : (opt == '2' ? 'Medium' : 'Local');

      print('\nEscolha o provedor para o perfil $slotName:');
      final pList = <String>[];
      for (final p in ['gemini', 'openai', 'anthropic', 'ollama', 'local_ai']) {
        if (!pList.contains(p)) pList.add(p);
      }

      for (var i = 0; i < pList.length; i++) {
        print('  [${i + 1}] ${pList[i]}');
      }
      stdout.write('Escolha um provedor [1-${pList.length}]: ');
      final pIdx = int.tryParse(stdin.readLineSync()?.trim() ?? '');
      if (pIdx == null || pIdx < 1 || pIdx > pList.length) continue;

      final chosenProvider = pList[pIdx - 1];
      var currentModels = AiModelCatalogService.getKnownModels(
        chosenProvider,
        userModels: config.providers[chosenProvider]?.knownModels,
      );
      try {
        final online = await AiModelCatalogService().fetchOnlineModels(
          providerId: chosenProvider,
          apiKey: config.providers[chosenProvider]?.apiKey,
          baseUrl: config.providers[chosenProvider]?.baseUrl,
        ).timeout(const Duration(milliseconds: 800));
        if (online.isNotEmpty) {
          final set = <String>{...online, ...currentModels};
          currentModels = set.toList();
        }
      } catch (_) {}

      print('\nEscolha o modelo para o perfil $slotName ($chosenProvider):');
      for (var i = 0; i < currentModels.length; i++) {
        print('  [${i + 1}] ${currentModels[i]}');
      }
      stdout.write('Escolha um modelo [1-${currentModels.length}] ou digite o nome: ');
      final mInput = stdin.readLineSync()?.trim() ?? '';
      final mIdx = int.tryParse(mInput);
      final chosenModel = (mIdx != null && mIdx >= 1 && mIdx <= currentModels.length)
          ? currentModels[mIdx - 1]
          : (mInput.isNotEmpty ? mInput : currentModels.first);

      final newSlot = AiModelSlotModel(provider: chosenProvider, model: chosenModel);
      config = AiConfigModel(
        activeProvider: config.activeProfile == slotKey ? chosenProvider : config.activeProvider,
        activeModel: config.activeProfile == slotKey ? chosenModel : config.activeModel,
        activeProfile: config.activeProfile,
        advanced: slotKey == 'advanced' ? newSlot : config.advanced,
        medium: slotKey == 'medium' ? newSlot : config.medium,
        local: slotKey == 'local' ? newSlot : config.local,
        providers: config.providers,
      );
      service.save(config);
      print('${AnsiColors.brightGreen}✅ Perfil $slotName configurado com: $chosenProvider ($chosenModel)!${AnsiColors.reset}');
    }
  }
  return config;
}
