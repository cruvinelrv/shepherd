import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import '../../domain/entities/ai_token_usage_entity.dart';
import '../../domain/services/ai_config_service.dart';
import '../../domain/services/ai_direct_inference_service.dart';
import '../../domain/services/ai_model_catalog_service.dart';
import '../../domain/services/ai_telemetry_service.dart';
import '../../domain/services/ai_file_patch_service.dart';
import '../../domain/services/ai_local_context_service.dart';
import '../../domain/services/ai_rag_service.dart';
import '../../domain/services/shepherd_platform_ai_service.dart';
import '../../domain/services/workspace_manifest_service.dart';
import '../../domain/services/ollama_url_helper.dart';
import '../../domain/services/ai_context_budget_service.dart';
import '../../domain/services/ai_reasoning_stream_transformer.dart';
import '../../domain/services/ai_mcp_integration_service.dart';
import '../../data/models/ai_vector_chunk_model.dart';
import '../../../utils/ai_i18n_helper.dart';
import '../../../utils/ansi_colors.dart';
import 'ai_config_command.dart';
import 'ai_index_command.dart';

/// Executes Shepherd AI prompts directly against the configured provider
/// (Google Gemini, OpenAI, Anthropic or local Ollama), supporting multiple files and interactive mode.
ArgParser createAiCommandParser() {
  final parser = ArgParser()
    ..addOption(
      'model',
      abbr: 'm',
      help: 'Modelo de IA a ser utilizado (ex: gemini-2.5-flash, gpt-4o, claude-3-7-sonnet, llama3.1).',
    )
    ..addOption(
      'provider',
      abbr: 'p',
      help: 'Provedor de IA: gemini, openai, anthropic ou ollama.',
    )
    ..addOption(
      'scope',
      abbr: 's',
      allowed: ['project', 'workspace'],
      defaultsTo: 'project',
      help: 'project: só o diretório atual. workspace: inclui o resumo de '
          'todos os projetos do .shepherd/workspace.yaml.',
    )
    ..addOption(
      'mode',
      allowed: ['fast', 'plan', 'auto'],
      defaultsTo: 'fast',
      help: 'Modo de execução: fast (direto), plan (planejamento) ou auto (autônomo).',
    )
    ..addOption(
      'tier',
      allowed: ['fast', 'deep'],
      defaultsTo: 'fast',
      help: 'Nível de atividade: fast (respostas rápidas) ou deep (raciocínio profundo).',
    )
    ..addMultiOption(
      'file',
      abbr: 'f',
      help: 'Anexa o conteúdo de um ou mais arquivos locais ao contexto da IA.',
    )
    ..addFlag(
      'rag',
      negatable: true,
      help: 'Ativa ou desativa a injeção de contexto via RAG (ativo por padrão em modelos locais).',
    )
    ..addFlag(
      'plan',
      negatable: false,
      help: 'Atalho para --mode plan (mostra os passos antes de agir).',
    )
    ..addFlag(
      'auto',
      negatable: false,
      help: 'Atalho para --mode auto.',
    )
    ..addFlag(
      'deep',
      negatable: false,
      help: 'Atalho para --tier deep.',
    )
    ..addFlag(
      'advanced',
      negatable: false,
      help: 'Use advanced model profile (EN).',
    )
    ..addFlag(
      'avancado',
      negatable: false,
      help: 'Usa o perfil de modelo avançado (PT).',
    )
    ..addFlag(
      'avanzado',
      negatable: false,
      help: 'Usa el perfil de modelo avanzado (ES).',
    )
    ..addFlag(
      'medium',
      negatable: false,
      help: 'Use medium model profile (EN).',
    )
    ..addFlag(
      'medio',
      negatable: false,
      help: 'Usa o perfil de modelo médio (PT / ES).',
    )
    ..addFlag(
      'local',
      negatable: false,
      help: 'Use local/LAN model profile (EN / PT / ES).',
    )
    ..addOption(
      'profile',
      help: 'Model profile to activate (advanced, medium, local).',
    );
  final configCmd = parser.addCommand('config');
  configCmd.addFlag('sync', abbr: 's', negatable: false, help: 'Sincroniza catálogo de modelos online.');

  final indexCmd = parser.addCommand('index');
  indexCmd.addFlag('force', abbr: 'f', negatable: false, help: 'Force re-indexing (EN).');
  indexCmd.addFlag('forcar', negatable: false, help: 'Forçar re-indexação (PT).');
  indexCmd.addFlag('forzar', negatable: false, help: 'Forzar reindexación (ES).');
  indexCmd.addFlag('status', abbr: 's', negatable: false, help: 'Show index status (EN/PT).');
  indexCmd.addFlag('estado', negatable: false, help: 'Estado del índice (ES).');
  indexCmd.addFlag('clear', negatable: false, help: 'Clear vector store (EN).');
  indexCmd.addFlag('limpar', negatable: false, help: 'Limpar base vetorial (PT).');
  indexCmd.addFlag('limpiar', negatable: false, help: 'Limpiar base vectorial (ES).');
  indexCmd.addOption('project', abbr: 'p', help: 'Project to index.');
  indexCmd.addOption('projeto', help: 'Projeto a indexar.');

  final indexarCmd = parser.addCommand('indexar');
  indexarCmd.addFlag('force', abbr: 'f', negatable: false);
  indexarCmd.addFlag('forcar', negatable: false);
  indexarCmd.addFlag('forzar', negatable: false);
  indexarCmd.addFlag('status', abbr: 's', negatable: false);
  indexarCmd.addFlag('estado', negatable: false);
  indexarCmd.addFlag('clear', negatable: false);
  indexarCmd.addFlag('limpar', negatable: false);
  indexarCmd.addFlag('limpiar', negatable: false);
  indexarCmd.addOption('project', abbr: 'p');
  indexarCmd.addOption('projeto');

  parser.addCommand('model');
  parser.addCommand('change-model');
  parser.addCommand('modelo');

  return parser;
}

/// Executes Shepherd AI prompts directly against the configured provider
/// (Google Gemini, OpenAI, Anthropic or local Ollama), supporting multiple files and interactive mode.
Future<void> runAiCommand(List<String> arguments) async {
  final parser = createAiCommandParser();

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print('❌ Erro: ${e.toString()}');
    print(
        'Uso: shepherd ai "seu prompt" [--advanced|--medium|--local] [-m modelo] [-p provedor]');
    print('     shepherd ai config [--sync]');
    print('     shepherd ai index [--force] [--status] [--clear]');
    print('     shepherd ai model [nome_do_modelo]');
    return;
  }

  if (argResults.command?.name == 'config') {
    await runAiConfigCommand(argResults.command!.arguments);
    return;
  }

  if (argResults.command?.name == 'index' || argResults.command?.name == 'indexar') {
    await runAiIndexCommand(argResults.command!.arguments);
    return;
  }

  if (argResults.command?.name == 'model' ||
      argResults.command?.name == 'change-model' ||
      argResults.command?.name == 'modelo') {
    await _handleModelSwitchCommand(argResults.command!.arguments);
    return;
  }

  final aiConfig = AiConfigService().load();

  // Multilingual profile resolution (EN / PT / ES)
  String? targetProfile;
  if (argResults['advanced'] == true ||
      argResults['avancado'] == true ||
      argResults['avanzado'] == true ||
      argResults['deep'] == true) {
    targetProfile = 'advanced';
  } else if (argResults['local'] == true) {
    targetProfile = 'local';
  } else if (argResults['medium'] == true ||
      argResults['medio'] == true) {
    targetProfile = 'medium';
  } else if (argResults['profile'] != null) {
    targetProfile = argResults['profile'] as String;
  }

  // Smart provider and model resolution
  String? resolvedProvider = argResults['provider'] as String?;
  String? resolvedModel = argResults['model'] as String?;

  if (resolvedProvider != null) {
    resolvedProvider = _normalizeProvider(resolvedProvider) ?? resolvedProvider;
  }

  if (resolvedProvider == null && resolvedModel != null) {
    resolvedProvider = _inferProviderFromModel(resolvedModel);
  }

  if (resolvedProvider == null && resolvedModel == null && aiConfig != null) {
    final slot = aiConfig.resolveProfileSlot(targetProfile);
    resolvedProvider = slot.provider;
    resolvedModel = slot.model;
  } else if (targetProfile != null && aiConfig != null) {
    final slot = aiConfig.resolveProfileSlot(targetProfile);
    resolvedProvider ??= slot.provider;
    resolvedModel ??= slot.model;
  }

  resolvedProvider ??= aiConfig?.activeProvider ?? 'gemini';

  final providerConfig = aiConfig?.providers[resolvedProvider.toLowerCase()];
  resolvedModel ??= aiConfig?.activeModel ?? providerConfig?.defaultModel ?? _defaultModelFor(resolvedProvider);

  final apiKey = providerConfig?.apiKey ?? _resolveEnvApiKey(resolvedProvider);
  final baseUrl = providerConfig?.baseUrl;

  final isLocalProvider = resolvedProvider.toLowerCase() == 'ollama' ||
      resolvedProvider.toLowerCase() == 'local_ai' ||
      resolvedProvider.toLowerCase() == 'lan_ai' ||
      (baseUrl != null && baseUrl.isNotEmpty && LanAiHelper.isLocalOrLan(baseUrl));
  final hasDirectAccess = isLocalProvider ||
      (apiKey != null && apiKey.isNotEmpty) ||
      (baseUrl != null && baseUrl.isNotEmpty);

  // If no direct configuration is available and no custom gateway is set
  final customGateway = Platform.environment['SHEPHERD_AI_GATEWAY_URL'];
  if (!hasDirectAccess && (customGateway == null || customGateway.isEmpty)) {
    stderr.writeln('\n❌ Provedor "$resolvedProvider" não configurado.');
    stderr.writeln('Execute `shepherd ai config` para configurar seu modelo e chave de API.');
    stderr.writeln('Ou defina uma variável de ambiente (ex: export GEMINI_API_KEY="sua_chave").\n');
    exitCode = 1;
    return;
  }

  // RAG: Active by default if the model/provider is local (free with zero token cost).
  // Inactive by default if it is a cloud/paid model (to avoid excessive API token usage).
  // If the user explicitly passes --rag or --no-rag, honor their choice.
  final bool ragExplicitlyProvided = argResults.wasParsed('rag');
  final bool useRag = ragExplicitlyProvided ? (argResults['rag'] as bool) : isLocalProvider;

  var tier = argResults['tier'] as String;
  if (argResults['deep'] == true) tier = 'deep';

  var mode = argResults['mode'] as String;
  if (argResults['plan'] == true) mode = 'plan';
  if (argResults['auto'] == true) mode = 'auto';

  final explicitFiles = argResults['file'] as List<String>? ?? [];
  final rawArgsPrompt = argResults.rest.join(' ');
  final fileResolution = AiLocalContextService.resolveLocalFiles(
    prompt: rawArgsPrompt,
    explicitFiles: explicitFiles,
  );

  if (fileResolution.resolvedFiles.isNotEmpty) {
    print('📂 Arquivos locais anexados: ${AnsiColors.brightGreen}${fileResolution.resolvedFiles.join(', ')}${AnsiColors.reset}');
  }
  if (fileResolution.missingFiles.isNotEmpty) {
    print('⚠️  Arquivos não encontrados: ${AnsiColors.brightYellow}${fileResolution.missingFiles.join(', ')}${AnsiColors.reset}');
  }

  final argsPrompt = fileResolution.enrichedPrompt;
  String stdinContent = '';

  if (!stdin.hasTerminal) {
    stdinContent = await utf8.decodeStream(stdin);
  }

  final scope = argResults['scope'] as String;
  final workspaceContext = _readWorkspaceContext(includeWorkspace: scope == 'workspace');

  // Modo de conversa interativo
  if (argsPrompt.isEmpty && stdinContent.isEmpty) {
    if (stdin.hasTerminal) {
      await _runInteractiveChat(
        provider: resolvedProvider,
        modelName: resolvedModel,
        apiKey: apiKey,
        baseUrl: baseUrl,
        workspaceContext: workspaceContext,
        tier: tier,
        initialMode: mode,
        profile: targetProfile ?? tier,
        initialRagEnabled: useRag,
        isLocalProvider: isLocalProvider,
        ragExplicitlyProvided: ragExplicitlyProvided,
      );
      return;
    }
    print('Uso:');
    print('  shepherd ai "seu prompt"');
    print('  shepherd ai "analise o código @lib/main.dart"');
    print('  shepherd ai -f pubspec.yaml "quais dependências estão listadas?"');
    print('  shepherd ai -m gpt-4o "analise a arquitetura"');
    print('  shepherd ai -m llama3.1 "gere um teste"');
    print('  shepherd ai --rag "como funciona a autenticação?"');
    print('  shepherd ai              # modo de conversa interativo');
    return;
  }

  final ragService = AiRagService();
  List<AiRagMatchModel> vectorMatches = [];
  String ragContext = '';

  final queryForRag = argsPrompt.isNotEmpty ? argsPrompt : stdinContent;
  if (queryForRag.isNotEmpty) {
    if (useRag) {
      if (ragService.isIndexed) {
        final topK = isLocalProvider ? 4 : 2;
        vectorMatches = await ragService.retrieveRelevantChunks(
          query: queryForRag,
          topK: topK,
        );
        if (vectorMatches.isNotEmpty) {
          ragContext = AiContextBudgetService.formatBudgetedRagContext(
            vectorMatches,
            isLocal: isLocalProvider,
          );
        }
      } else {
        print('${AnsiColors.gray}${AiI18nHelper.ragIndexTip()}${AnsiColors.reset}');
      }
    } else {
      if (ragService.isIndexed && !isLocalProvider && !ragExplicitlyProvided) {
        print('${AnsiColors.gray}${AiI18nHelper.ragCloudTip()}${AnsiColors.reset}');
      }
    }
  }

  final buffer = StringBuffer();
  buffer.writeln(_formatSystemPreamble(
    workingDir: Directory.current.path,
    isLocal: isLocalProvider,
  ));
  if (workspaceContext.isNotEmpty) {
    buffer.writeln('--- Contexto do Workspace Shepherd ---');
    buffer.writeln(workspaceContext);
    buffer.writeln();
  }
  if (ragContext.isNotEmpty) {
    buffer.writeln(ragContext);
    buffer.writeln();
  }
  final modePrompt = _formatModePrompt(mode);
  if (modePrompt.isNotEmpty) {
    buffer.write(modePrompt);
  }
  final tierPrompt = _formatTierPrompt(tier);
  if (tierPrompt.isNotEmpty) {
    buffer.write(tierPrompt);
  }
  if (argsPrompt.isNotEmpty) {
    buffer.writeln(argsPrompt);
  }
  if (stdinContent.isNotEmpty) {
    if (argsPrompt.isNotEmpty) buffer.writeln('\n--- Entrada (stdin) ---');
    buffer.writeln(stdinContent);
  }

  final finalPrompt = buffer.toString().trim();

  // Custom Gateway execution (if explicitly configured via env)
  if (customGateway != null && customGateway.isNotEmpty) {
    final platformService = ShepherdPlatformAiService();
    try {
      final res = await platformService.generate(
        goal: finalPrompt,
        mode: mode,
        tier: tier,
        workspaceContext: workspaceContext,
      );
      if (res.text != null) print(res.text);
      _printModelFooter(
        provider: 'Shepherd Gateway ($customGateway)',
        model: res.modelUsed ?? resolvedModel,
        tier: tier,
        mode: mode,
        latencyMs: res.latencyMs,
        tokensUsed: res.tokensUsed,
      );
      return;
    } catch (e) {
      stderr.writeln('⚠️ Gateway customizado falhou: $e. Recorrendo à execução direta...');
    }
  }

  // Direct execution (BYOK / Local)
  final inferenceService = AiDirectInferenceService();
  final stopwatch = Stopwatch()..start();

  try {
    AiTokenUsageEntity? tokenUsage;
    final responseStream = inferenceService.generateStream(
      prompt: finalPrompt,
      provider: resolvedProvider,
      model: resolvedModel,
      apiKey: apiKey,
      baseUrl: baseUrl,
      onUsage: (u) => tokenUsage = u,
    );

    final outputBuffer = StringBuffer();
    final reasoningTransformer = const AiReasoningStreamTransformer();
    var inThinking = false;

    await for (final item in responseStream.transform(reasoningTransformer)) {
      if (item.isReasoning) {
        if (!inThinking) {
          inThinking = true;
          stdout.write('\n${AnsiColors.gray}💭 Pensamento:\n');
        }
        stdout.write('${AnsiColors.gray}${item.text}${AnsiColors.reset}');
      } else {
        if (inThinking) {
          inThinking = false;
          stdout.write('\n\n');
        }
        stdout.write(item.text);
        outputBuffer.write(item.text);
      }
    }
    if (inThinking) {
      stdout.write('\n\n');
    }
    stopwatch.stop();
    stdout.writeln();

    final hasFiles = fileResolution.resolvedFiles.isNotEmpty;
    final hasWorkspace = workspaceContext.isNotEmpty;
    String ragStatus;
    if (vectorMatches.isNotEmpty) {
      ragStatus = 'local-vector (${vectorMatches.length} chunks)';
    } else if (hasFiles && hasWorkspace) {
      ragStatus = 'Local (${fileResolution.resolvedFiles.length} arqs + Workspace)';
    } else if (hasFiles) {
      ragStatus = 'Local (${fileResolution.resolvedFiles.length} arqs)';
    } else if (hasWorkspace) {
      ragStatus = 'Local (Workspace)';
    } else {
      ragStatus = 'Desativado';
    }

    _printModelFooter(
      provider: _providerDisplayName(resolvedProvider),
      model: resolvedModel,
      tier: tier,
      mode: mode,
      latencyMs: stopwatch.elapsedMilliseconds,
      ragStatus: ragStatus,
      tokens: tokenUsage,
    );

    final cleanOutput = AiReasoningStreamTransformer.stripThinking(outputBuffer.toString());
    final extractedTools = AiMcpIntegrationService.extractToolCalls(cleanOutput);
    unawaited(AiTelemetryService().sendAiTelemetry(
      provider: resolvedProvider,
      model: resolvedModel,
      durationMs: stopwatch.elapsedMilliseconds,
      tokens: tokenUsage,
      ragResultCount: vectorMatches.length + fileResolution.resolvedFiles.length + (workspaceContext.isNotEmpty ? 1 : 0),
      profile: targetProfile ?? tier,
      toolCallsCount: extractedTools.length,
      mcpToolCalls: extractedTools,
    ));

    final fileActions = AiFilePatchService.extractActions(cleanOutput);
    if (fileActions.isNotEmpty) {
      final autoApprove = mode == 'auto';
      await AiFilePatchService.promptAndApply(fileActions, autoApprove: autoApprove);
    }
  } catch (e) {
    stderr.writeln('\n❌ Erro na execução direta com $resolvedProvider: $e\n');
    if (resolvedProvider == 'ollama' || e.toString().contains('11434') || e.toString().contains('Connection refused')) {
      stderr.writeln('💡 O serviço do Ollama não está ativo ou acessível.');
      stderr.writeln('   • Para rodar localmente: inicie o Ollama com `ollama serve`.');
      stderr.writeln('   • Se estiver em outra máquina na rede: configure o IP com `shepherd ai config` ou `/model` (opção [u]).');
      stderr.writeln('   • Para voltar para modelos em nuvem: use `shepherd ai model gemini` ou `shepherd ai --tier fast`.\n');
    }
    exitCode = 1;
  }
}

/// Direct interactive chat mode.
Future<void> _runInteractiveChat({
  required String provider,
  required String modelName,
  String? apiKey,
  String? baseUrl,
  required String workspaceContext,
  required String tier,
  String initialMode = 'fast',
  String? profile,
  bool initialRagEnabled = true,
  bool isLocalProvider = false,
  bool ragExplicitlyProvided = false,
}) async {
  const exitWords = {'exit', 'sair', 'quit', 'q'};
  final history = <Map<String, String>>[];
  final inferenceService = AiDirectInferenceService();
  var currentProvider = provider;
  var currentModelName = modelName;
  var currentApiKey = apiKey;
  var currentBaseUrl = baseUrl;
  var currentIsLocal = isLocalProvider;
  var ragEnabled = initialRagEnabled;
  var currentMode = initialMode;
  var currentTier = tier;

  print('\n${AnsiColors.bold}Shepherd AI — Modo Interativo${AnsiColors.reset}');
  print('────────────────────────────────────────────────────────────────────────');
  final ragStatusStr = AiI18nHelper.ragStatusLabel(enabled: ragEnabled, isLocal: currentIsLocal);
  print('🧠 Motor: ${AnsiColors.brightCyan}$currentModelName${AnsiColors.reset} | Modo: ${AnsiColors.brightCyan}$currentMode${AnsiColors.reset} | Tier: ${AnsiColors.brightCyan}$currentTier${AnsiColors.reset} | Provedor: ${AnsiColors.brightGreen}${_providerDisplayName(currentProvider)}${AnsiColors.reset} | RAG: ${AnsiColors.brightGreen}$ragStatusStr${AnsiColors.reset}');
  if (!ragEnabled && !currentIsLocal && !ragExplicitlyProvided) {
    print('${AnsiColors.gray}${AiI18nHelper.ragCloudTip()}${AnsiColors.reset}');
  }
  final mcpTools = await AiMcpIntegrationService.loadTools();
  if (mcpTools.isNotEmpty) {
    print('🔧 MCP: ${AnsiColors.brightMagenta}${mcpTools.length} ferramenta(s) ativa(s)${AnsiColors.reset} (${mcpTools.map((t) => t.name).take(3).join(', ')}${mcpTools.length > 3 ? '...' : ''})');
  }
  print('Digite sua pergunta ou use @arquivo para anexar contexto.');
  print('Comandos: "/plan" planejar | "/auto" autônomo | "/fast" direto | "/model" trocar modelo | "/rag on|off" | "/help" ajuda | "sair" encerrar.\n');

  var firstMessage = true;
  final chatRagService = AiRagService();

  while (true) {
    stdout.write('[$currentMode] > ');
    final input = stdin.readLineSync();
    if (input == null) break;
    var question = input.trim();
    if (question.isEmpty) continue;
    if (exitWords.contains(question.toLowerCase())) break;

    if (question.startsWith('/model') ||
        question.startsWith('/modelo') ||
        question.startsWith('/change-model') ||
        question == '/trocar-modelo') {
      final parts = question.split(' ');
      final arg = parts.length > 1 ? parts.sublist(1).join(' ').trim() : '';

      final aiConfig = AiConfigService().load();
      final options = await _buildModelSwitchOptions(aiConfig);

      _ModelSwitchOption? selected;
      if (arg.isEmpty) {
        print('\n${AnsiColors.bold}🤖 Trocar de Modelo / Provedor${AnsiColors.reset}');
        print('────────────────────────────────────────────────────────────────────────');
        final currentRagStatus = AiI18nHelper.ragStatusLabel(enabled: ragEnabled, isLocal: currentIsLocal);
        print('Modelo Atual: ${AnsiColors.brightCyan}$currentModelName${AnsiColors.reset} (${_providerDisplayName(currentProvider)}) | RAG: ${AnsiColors.brightGreen}$currentRagStatus${AnsiColors.reset}\n');
        print('Opções disponíveis:');
        for (var i = 0; i < options.length; i++) {
          final opt = options[i];
          final isCurrent = opt.provider == currentProvider && opt.model == currentModelName;
          final check = isCurrent ? ' ${AnsiColors.brightGreen}★ (Ativo)${AnsiColors.reset}' : '';
          print('  [${i + 1}] ${opt.label}$check');
        }
        print('────────────────────────────────────────────────────────────────────────');
        stdout.write('Escolha uma opção [1-${options.length}] ou digite o nome do modelo (ou Enter para cancelar): ');
        final choiceInput = stdin.readLineSync()?.trim();
        if (choiceInput == null || choiceInput.isEmpty) {
          print('ℹ️  Troca cancelada. Mantido: $currentModelName.\n');
          continue;
        }
        if (choiceInput == '1' || choiceInput.toLowerCase() == 'ollama' || choiceInput.toLowerCase() == 'local') {
          selected = await _promptOllamaModelSelection(
            aiConfig: aiConfig,
            currentModel: currentModelName,
          );
        } else if (choiceInput == '5' ||
            choiceInput.toLowerCase() == 'opencode' ||
            choiceInput.toLowerCase() == 'opencode.ai' ||
            choiceInput.toLowerCase() == 'zen') {
          selected = await _promptOpenCodeModelSelection(
            aiConfig: aiConfig,
            currentModel: currentModelName,
          );
        } else {
          selected = _selectModelOption(choiceInput, options, aiConfig);
        }
      } else {
        if (arg.toLowerCase() == 'ollama' || arg.toLowerCase() == 'local') {
          selected = await _promptOllamaModelSelection(
            aiConfig: aiConfig,
            currentModel: currentModelName,
          );
        } else if (arg.toLowerCase() == 'opencode' ||
            arg.toLowerCase() == 'opencode.ai' ||
            arg.toLowerCase() == 'zen') {
          selected = await _promptOpenCodeModelSelection(
            aiConfig: aiConfig,
            currentModel: currentModelName,
          );
        } else {
          selected = _selectModelOption(arg, options, aiConfig);
        }
      }

      if (selected != null) {
        currentProvider = selected.provider;
        currentModelName = selected.model;
        currentApiKey = selected.apiKey;
        currentBaseUrl = selected.baseUrl;
        currentIsLocal = selected.isLocal;
        ragEnabled = selected.isLocal; // Ativa RAG se for local, desativa se for nuvem
        final statusLabel = AiI18nHelper.ragStatusLabel(enabled: ragEnabled, isLocal: currentIsLocal);
        print('\n${AnsiColors.brightGreen}✅ Modelo alterado para: $currentModelName (${_providerDisplayName(currentProvider)})${AnsiColors.reset}');
        print('🧠 RAG atualizado para: ${AnsiColors.brightGreen}$statusLabel${AnsiColors.reset}\n');

        if (aiConfig != null) {
          final updatedProviders = Map<String, AiProviderConfigEntity>.from(aiConfig.providers);
          final existingProv = updatedProviders[currentProvider];
          final currentKnown = List<String>.from(existingProv?.knownModels ?? []);
          if (!currentKnown.contains(currentModelName)) {
            currentKnown.add(currentModelName);
          }
          updatedProviders[currentProvider] = AiProviderConfigModel(
            id: currentProvider,
            apiKey: selected.apiKey ?? existingProv?.apiKey ?? currentApiKey,
            baseUrl: selected.baseUrl ?? existingProv?.baseUrl ?? currentBaseUrl,
            defaultModel: currentModelName,
            knownModels: currentKnown,
          );
          final updated = aiConfig.copyWith(
            activeProvider: currentProvider,
            activeModel: currentModelName,
            providers: updatedProviders,
          );
          AiConfigService().save(updated);
        }
      } else {
        print('❌ Opção ou modelo não reconhecido. Digite "/model" para ver a lista.\n');
      }
      continue;
    }

    if (question.startsWith('/rag')) {
      final parts = question.split(' ');
      if (parts.length > 1 && parts[1].toLowerCase() == 'on') {
        ragEnabled = true;
        print('✅ RAG ativado para esta sessão de chat.');
      } else if (parts.length > 1 && parts[1].toLowerCase() == 'off') {
        ragEnabled = false;
        print('🛑 RAG desativado para esta sessão de chat.');
      } else {
        print('ℹ️  Status do RAG: ${ragEnabled ? 'Ativado' : 'Desativado'} (use "/rag on" ou "/rag off").');
      }
      continue;
    }

    if (question == '/mcp' || question == '/tools' || question == '/ferramentas') {
      if (mcpTools.isEmpty) {
        print('ℹ️ Nenhuma ferramenta MCP configurada. Adicione servidores em `.shepherd/mcp.json`.\n');
      } else {
        print('\n${AnsiColors.bold}🔧 Ferramentas MCP Disponíveis no Workspace:${AnsiColors.reset}');
        for (final t in mcpTools) {
          print('  • [${t.serverName}] ${AnsiColors.brightCyan}${t.name}${AnsiColors.reset}: ${t.description}');
        }
        print('');
      }
      continue;
    }

    if (question == '/plan' || question == '/plano') {
      currentMode = 'plan';
      print('\n📋 ${AnsiColors.bold}Modo PLAN ativado${AnsiColors.reset}: As próximas respostas focarão em planejamento arquitetural detalhado passo a passo.\n');
      continue;
    }
    if (question.startsWith('/plan ') || question.startsWith('/plano ')) {
      currentMode = 'plan';
      question = question.substring(question.indexOf(' ') + 1).trim();
      print('📋 ${AnsiColors.bold}Executando em Modo PLAN (Planejamento)...${AnsiColors.reset}');
    }

    if (question == '/auto') {
      currentMode = 'auto';
      print('\n⚡ ${AnsiColors.bold}Modo AUTO ativado${AnsiColors.reset}: As próximas respostas gerarão alterações de código completas prontas para aplicação direta.\n');
      continue;
    }
    if (question.startsWith('/auto ')) {
      currentMode = 'auto';
      question = question.substring(question.indexOf(' ') + 1).trim();
      print('⚡ ${AnsiColors.bold}Executando em Modo AUTO (Autônomo)...${AnsiColors.reset}');
    }

    if (question == '/fast') {
      currentMode = 'fast';
      print('\n🚀 ${AnsiColors.bold}Modo FAST ativado${AnsiColors.reset}: Respostas diretas e objetivas.\n');
      continue;
    }
    if (question.startsWith('/fast ')) {
      currentMode = 'fast';
      question = question.substring(question.indexOf(' ') + 1).trim();
      print('🚀 ${AnsiColors.bold}Executando em Modo FAST (Direto)...${AnsiColors.reset}');
    }

    if (question == '/mode' || question == '/modo') {
      print('\nℹ️ Modo de execução atual: ${AnsiColors.brightCyan}$currentMode${AnsiColors.reset}');
      print('   Para alternar use: "/plan" (planejamento), "/auto" (autônomo) ou "/fast" (direto).\n');
      continue;
    }
    if (question.startsWith('/mode ') || question.startsWith('/modo ')) {
      final parts = question.split(' ');
      final target = parts.length > 1 ? parts[1].toLowerCase().trim() : '';
      if (['fast', 'plan', 'auto'].contains(target)) {
        currentMode = target;
        print('\n✅ Modo de execução alterado para: ${AnsiColors.brightCyan}$currentMode${AnsiColors.reset}\n');
      } else {
        print('\n❌ Modo inválido "$target". Opções: fast, plan, auto.\n');
      }
      continue;
    }

    if (question == '/tier') {
      print('\nℹ️ Tier atual: ${AnsiColors.brightCyan}$currentTier${AnsiColors.reset}');
      print('   Para alternar use: "/tier fast" ou "/tier deep".\n');
      continue;
    }
    if (question.startsWith('/tier ')) {
      final parts = question.split(' ');
      final target = parts.length > 1 ? parts[1].toLowerCase().trim() : '';
      if (['fast', 'deep'].contains(target)) {
        currentTier = target;
        print('\n✅ Tier alterado para: ${AnsiColors.brightCyan}$currentTier${AnsiColors.reset}\n');
      } else {
        print('\n❌ Tier inválido "$target". Opções: fast, deep.\n');
      }
      continue;
    }

    if (question == '/help' || question == '/ajuda' || question == '/?') {
      print('\n${AnsiColors.bold}📖 Comandos Disponíveis no Shepherd AI:${AnsiColors.reset}');
      print('  ${AnsiColors.brightCyan}/plan [tarefa]${AnsiColors.reset}         Alterna para modo PLAN (planejamento passo a passo)');
      print('  ${AnsiColors.brightCyan}/auto [tarefa]${AnsiColors.reset}         Alterna para modo AUTO (autônomo com aplicação de patches)');
      print('  ${AnsiColors.brightCyan}/fast [tarefa]${AnsiColors.reset}         Alterna para modo FAST (respostas diretas e rápidas)');
      print('  ${AnsiColors.brightCyan}/mode <fast|plan|auto>${AnsiColors.reset} Exibe ou define o modo de execução');
      print('  ${AnsiColors.brightCyan}/tier <fast|deep>${AnsiColors.reset}      Alterna o nível de raciocínio (fast vs deep)');
      print('  ${AnsiColors.brightCyan}/model${AnsiColors.reset}                  Troca o modelo ou provedor ativo');
      print('  ${AnsiColors.brightCyan}/rag on|off${AnsiColors.reset}            Ativa ou desativa a busca vetorial no workspace');
      print('  ${AnsiColors.brightCyan}/mcp${AnsiColors.reset}                    Lista as ferramentas MCP disponíveis');
      print('  ${AnsiColors.brightCyan}@caminho/arquivo${AnsiColors.reset}       Anexa o arquivo especificado ao contexto da pergunta');
      print('  ${AnsiColors.brightCyan}sair | exit${AnsiColors.reset}            Encerra a sessão interativa\n');
      continue;
    }

    final fileResolution = AiLocalContextService.resolveLocalFiles(prompt: question);
    if (fileResolution.resolvedFiles.isNotEmpty) {
      print('📂 Arquivos anexados: ${AnsiColors.brightGreen}${fileResolution.resolvedFiles.join(', ')}${AnsiColors.reset}');
    }
    if (fileResolution.missingFiles.isNotEmpty) {
      print('⚠️  Arquivos não encontrados: ${AnsiColors.brightYellow}${fileResolution.missingFiles.join(', ')}${AnsiColors.reset}');
    }

    final enrichedQuestion = fileResolution.enrichedPrompt;
    final promptBuffer = StringBuffer();

    if (firstMessage) {
      promptBuffer.writeln(_formatSystemPreamble(
        workingDir: Directory.current.path,
        isLocal: currentIsLocal,
      ));
      if (workspaceContext.isNotEmpty) {
        promptBuffer.writeln('--- Contexto do Workspace Shepherd ---');
        promptBuffer.writeln(workspaceContext);
        promptBuffer.writeln();
      }
      if (mcpTools.isNotEmpty) {
        promptBuffer.writeln(AiMcpIntegrationService.formatToolsInstruction(mcpTools));
        promptBuffer.writeln();
      }
      firstMessage = false;
    }

    final modePrompt = _formatModePrompt(currentMode);
    if (modePrompt.isNotEmpty) {
      promptBuffer.writeln(modePrompt);
    }
    final tierPrompt = _formatTierPrompt(currentTier);
    if (tierPrompt.isNotEmpty) {
      promptBuffer.writeln(tierPrompt);
    }

    List<AiRagMatchModel> chatRagMatches = [];
    if (ragEnabled && chatRagService.isIndexed) {
      final topK = currentIsLocal ? 3 : 2;
      chatRagMatches = await chatRagService.retrieveRelevantChunks(
        query: enrichedQuestion,
        topK: topK,
      );
      if (chatRagMatches.isNotEmpty) {
        promptBuffer.writeln(AiContextBudgetService.formatBudgetedRagContext(
          chatRagMatches,
          isLocal: currentIsLocal,
        ));
        promptBuffer.writeln();
      }
    }

    if (history.isNotEmpty) {
      promptBuffer.writeln('--- Histórico Recente da Conversa ---');
      final compactedHistory = AiContextBudgetService.compactHistory(
        history,
        isLocal: currentIsLocal,
        maxTurns: currentIsLocal ? 6 : 4,
      );
      for (final h in compactedHistory) {
        promptBuffer.writeln('${h['role'] == 'user' ? 'Usuário' : 'Assistente'}: ${h['content']}');
      }
      promptBuffer.writeln();
    }

    promptBuffer.writeln(enrichedQuestion);
    final finalPrompt = promptBuffer.toString().trim();

    final stopwatch = Stopwatch()..start();
    AiTokenUsageEntity? tokenUsage;
    try {
      final responseStream = inferenceService.generateStream(
        prompt: finalPrompt,
        provider: currentProvider,
        model: currentModelName,
        apiKey: currentApiKey,
        baseUrl: currentBaseUrl,
        onUsage: (u) => tokenUsage = u,
      );

      final answerBuffer = StringBuffer();
      final reasoningTransformer = const AiReasoningStreamTransformer();
      var inThinking = false;

      await for (final item in responseStream.transform(reasoningTransformer)) {
        if (item.isReasoning) {
          if (!inThinking) {
            inThinking = true;
            stdout.write('\n${AnsiColors.gray}💭 Pensamento:\n');
          }
          stdout.write('${AnsiColors.gray}${item.text}${AnsiColors.reset}');
        } else {
          if (inThinking) {
            inThinking = false;
            stdout.write('\n\n');
          }
          stdout.write(item.text);
          answerBuffer.write(item.text);
        }
      }
      if (inThinking) {
        stdout.write('\n\n');
      }
      stopwatch.stop();
      stdout.writeln();

      final hasFiles = fileResolution.resolvedFiles.isNotEmpty;
      final hasWorkspace = workspaceContext.isNotEmpty;
      String chatRagStatus;
      if (chatRagMatches.isNotEmpty) {
        chatRagStatus = 'local-vector (${chatRagMatches.length} chunks)';
      } else if (hasFiles && hasWorkspace) {
        chatRagStatus = 'Local (${fileResolution.resolvedFiles.length} arqs + Workspace)';
      } else if (hasFiles) {
        chatRagStatus = 'Local (${fileResolution.resolvedFiles.length} arqs)';
      } else if (hasWorkspace) {
        chatRagStatus = 'Local (Workspace)';
      } else {
        chatRagStatus = 'Desativado';
      }

      _printModelFooter(
        provider: _providerDisplayName(currentProvider),
        model: currentModelName,
        tier: currentTier,
        mode: currentMode,
        latencyMs: stopwatch.elapsedMilliseconds,
        ragStatus: chatRagStatus,
        tokens: tokenUsage,
      );

      final cleanAnswer = AiReasoningStreamTransformer.stripThinking(answerBuffer.toString());
      final toolCalls = AiMcpIntegrationService.extractToolCalls(cleanAnswer);

      unawaited(AiTelemetryService().sendAiTelemetry(
        provider: currentProvider,
        model: currentModelName,
        durationMs: stopwatch.elapsedMilliseconds,
        tokens: tokenUsage,
        ragResultCount: chatRagMatches.length + fileResolution.resolvedFiles.length + (workspaceContext.isNotEmpty ? 1 : 0),
        profile: profile ?? currentTier,
        toolCallsCount: toolCalls.length,
        mcpToolCalls: toolCalls,
      ));

      history.add({'role': 'user', 'content': question});
      history.add({'role': 'assistant', 'content': cleanAnswer});

      final fileActions = AiFilePatchService.extractActions(cleanAnswer);
      if (fileActions.isNotEmpty) {
        final autoApprove = currentMode == 'auto';
        await AiFilePatchService.promptAndApply(fileActions, autoApprove: autoApprove);
      }

      if (toolCalls.isNotEmpty) {
        for (final call in toolCalls) {
          print('\n${AnsiColors.brightCyan}⚙️ Chamada de Ferramenta MCP detectada:${AnsiColors.reset} [${call.serverName}] ${call.toolName}');
          if (call.arguments.isNotEmpty) {
            print('   Argumentos: ${jsonEncode(call.arguments)}');
          }
          stdout.write('   Deseja executar esta ferramenta? (S/n): ');
          final confirm = stdin.readLineSync()?.trim().toLowerCase();
          if (confirm == null || confirm.isEmpty || confirm == 's' || confirm == 'y' || confirm == 'sim') {
            stdout.write('   ⏳ Executando ${call.toolName}... ');
            final result = await AiMcpIntegrationService.executeToolCall(call);
            print('${AnsiColors.brightGreen}Concluído!${AnsiColors.reset}');
            print('   Resultado:\n${AnsiColors.gray}$result${AnsiColors.reset}\n');
            history.add({
              'role': 'user',
              'content': '[Resultado da Ferramenta MCP ${call.serverName}:${call.toolName}]:\n$result',
            });
          } else {
            print('   🚫 Execução cancelada pelo usuário.\n');
          }
        }
      }
    } catch (e) {
      stderr.writeln('\n❌ Erro ao comunicar com $currentProvider: $e\n');
      if (currentProvider == 'ollama' || e.toString().contains('11434') || e.toString().contains('Connection refused')) {
        stderr.writeln('💡 O serviço do Ollama não está acessível no endereço configurado ($currentBaseUrl).');
        stderr.writeln('   • Se estiver na rede local: verifique se a máquina remota está ligada e o Ollama acessível na porta 11434.');
        stderr.writeln('   • Para alterar o IP do Ollama ou voltar para a nuvem: digite `/model` (opção [u]).\n');
      }
    }
  }

  print('\nAté mais!');
}

Future<void> _handleModelSwitchCommand(List<String> args) async {
  final aiConfig = AiConfigService().load();
  final options = await _buildModelSwitchOptions(aiConfig);
  final arg = args.join(' ').trim();

  _ModelSwitchOption? selected;
  if (arg.isEmpty) {
    final currentProvider = aiConfig?.activeProvider ?? 'gemini';
    final currentModel = aiConfig?.activeModel ?? 'gemini-2.5-flash';
    final isLocal = currentProvider == 'ollama' || currentProvider == 'local_ai';

    print('\n${AnsiColors.bold}🤖 Shepherd AI — Trocar de Modelo / Provedor${AnsiColors.reset}');
    print('────────────────────────────────────────────────────────────────────────');
    final currentRagStatus = AiI18nHelper.ragStatusLabel(enabled: isLocal, isLocal: isLocal);
    print('Modelo Atual: ${AnsiColors.brightCyan}$currentModel${AnsiColors.reset} (${_providerDisplayName(currentProvider)}) | RAG: ${AnsiColors.brightGreen}$currentRagStatus${AnsiColors.reset}\n');
    print('Opções disponíveis:');
    for (var i = 0; i < options.length; i++) {
      final opt = options[i];
      final isCurrent = opt.provider == currentProvider && opt.model == currentModel;
      final check = isCurrent ? ' ${AnsiColors.brightGreen}★ (Ativo)${AnsiColors.reset}' : '';
      print('  [${i + 1}] ${opt.label}$check');
    }
    print('────────────────────────────────────────────────────────────────────────');
    stdout.write('Escolha uma opção [1-${options.length}] ou digite o nome do modelo (ou Enter para cancelar): ');
    final choiceInput = stdin.readLineSync()?.trim();
    if (choiceInput == null || choiceInput.isEmpty) {
      print('ℹ️  Operação cancelada. Mantido: $currentModel.\n');
      return;
    }
    if (choiceInput == '1' || choiceInput.toLowerCase() == 'ollama' || choiceInput.toLowerCase() == 'local') {
      selected = await _promptOllamaModelSelection(
        aiConfig: aiConfig,
        currentModel: currentModel,
      );
    } else if (choiceInput == '5' ||
        choiceInput.toLowerCase() == 'opencode' ||
        choiceInput.toLowerCase() == 'opencode.ai' ||
        choiceInput.toLowerCase() == 'zen') {
      selected = await _promptOpenCodeModelSelection(
        aiConfig: aiConfig,
        currentModel: currentModel,
      );
    } else {
      selected = _selectModelOption(choiceInput, options, aiConfig);
    }
  } else {
    if (arg.toLowerCase() == 'ollama' || arg.toLowerCase() == 'local') {
      final currentModel = aiConfig?.activeModel ?? 'gemini-2.5-flash';
      selected = await _promptOllamaModelSelection(
        aiConfig: aiConfig,
        currentModel: currentModel,
      );
    } else if (arg.toLowerCase() == 'opencode' ||
        arg.toLowerCase() == 'opencode.ai' ||
        arg.toLowerCase() == 'zen') {
      final currentModel = aiConfig?.activeModel ?? 'qwen3.8-max';
      selected = await _promptOpenCodeModelSelection(
        aiConfig: aiConfig,
        currentModel: currentModel,
      );
    } else {
      selected = _selectModelOption(arg, options, aiConfig);
    }
  }

  if (selected != null) {
    if (aiConfig != null) {
      final updatedProviders = Map<String, AiProviderConfigEntity>.from(aiConfig.providers);
      final existingProv = updatedProviders[selected.provider];
      final currentKnown = List<String>.from(existingProv?.knownModels ?? []);
      if (!currentKnown.contains(selected.model)) {
        currentKnown.add(selected.model);
      }
      updatedProviders[selected.provider] = AiProviderConfigModel(
        id: selected.provider,
        apiKey: selected.apiKey ?? existingProv?.apiKey,
        baseUrl: selected.baseUrl ?? existingProv?.baseUrl,
        defaultModel: selected.model,
        knownModels: currentKnown,
      );
      final updated = aiConfig.copyWith(
        activeProvider: selected.provider,
        activeModel: selected.model,
        providers: updatedProviders,
      );
      AiConfigService().save(updated);
    }
    final statusLabel = AiI18nHelper.ragStatusLabel(enabled: selected.isLocal, isLocal: selected.isLocal);
    print('\n${AnsiColors.brightGreen}✅ Modelo padrão atualizado para: ${selected.model} (${_providerDisplayName(selected.provider)})${AnsiColors.reset}');
    print('🧠 RAG Padrão: ${AnsiColors.brightGreen}$statusLabel${AnsiColors.reset}\n');
  } else {
    print('❌ Opção ou modelo não reconhecido. Digite "shepherd ai model" para ver a lista.\n');
  }
}

class _ModelSwitchOption {
  final String label;
  final String provider;
  final String model;
  final String? apiKey;
  final String? baseUrl;
  final bool isLocal;
  final List<String> aliases;

  const _ModelSwitchOption({
    required this.label,
    required this.provider,
    required this.model,
    this.apiKey,
    this.baseUrl,
    required this.isLocal,
    this.aliases = const [],
  });
}

Future<List<_ModelSwitchOption>> _buildModelSwitchOptions(AiConfigModel? aiConfig) async {
  final options = <_ModelSwitchOption>[];

  // 1. Local (Ollama)
  final ollamaCfg = aiConfig?.providers['ollama'];
  final localModel = aiConfig?.local?.model ?? ollamaCfg?.defaultModel ?? 'llama3.1';
  final localUrl = OllamaUrlHelper.normalize(ollamaCfg?.baseUrl);
  final isRemoteLan = !localUrl.contains('localhost') && !localUrl.contains('127.0.0.1');
  final lanBadge = isRemoteLan ? ' (LAN: $localUrl)' : '';
  options.add(_ModelSwitchOption(
    label: '${AnsiColors.brightGreen}🏠 Local (Ollama)${AnsiColors.reset}       : Escolher modelo do Ollama [RAG Ativo / Custo Zero] (Atual: $localModel$lanBadge)',
    provider: 'ollama',
    model: localModel,
    baseUrl: localUrl,
    isLocal: true,
    aliases: ['1', 'local', 'ollama', 'lan'],
  ));

  // 2. OpenAI (ChatGPT)
  final openAiCfg = aiConfig?.providers['openai'];
  final openAiModel = openAiCfg?.defaultModel ?? 'gpt-4o';
  final openAiKey = openAiCfg?.apiKey ?? _resolveEnvApiKey('openai');
  options.add(_ModelSwitchOption(
    label: '${AnsiColors.brightYellow}🌐 OpenAI (ChatGPT)${AnsiColors.reset}     : $openAiModel [Econômico / Nuvem]',
    provider: 'openai',
    model: openAiModel,
    apiKey: openAiKey,
    isLocal: false,
    aliases: ['2', 'openai', 'chatgpt', 'chat_gpt', 'chat-gpt', 'gpt'],
  ));

  // 3. Anthropic (Claude)
  final claudeCfg = aiConfig?.providers['anthropic'];
  final claudeModel = claudeCfg?.defaultModel ?? 'claude-sonnet-5';
  final claudeKey = claudeCfg?.apiKey ?? _resolveEnvApiKey('anthropic');
  options.add(_ModelSwitchOption(
    label: '${AnsiColors.brightBlue}🟣 Anthropic (Claude)${AnsiColors.reset}   : $claudeModel [Raciocínio / Nuvem]',
    provider: 'anthropic',
    model: claudeModel,
    apiKey: claudeKey,
    isLocal: false,
    aliases: ['3', 'anthropic', 'claude'],
  ));

  // 4. Google (Gemini)
  final geminiCfg = aiConfig?.providers['gemini'];
  final geminiModel = aiConfig?.medium?.model ?? geminiCfg?.defaultModel ?? 'gemini-2.5-flash';
  final geminiKey = geminiCfg?.apiKey ?? _resolveEnvApiKey('gemini');
  options.add(_ModelSwitchOption(
    label: '${AnsiColors.brightCyan}🔷 Google (Gemini)${AnsiColors.reset}      : $geminiModel [Rápido / Nuvem]',
    provider: 'gemini',
    model: geminiModel,
    apiKey: geminiKey,
    isLocal: false,
    aliases: ['4', 'gemini', 'google'],
  ));

  // 5. OpenCode Zen (opencode.ai)
  final openCodeCfg = aiConfig?.providers['opencode'];
  final openCodeModel = openCodeCfg?.defaultModel ?? 'qwen3.8-max';
  final openCodeKey = openCodeCfg?.apiKey ?? _resolveEnvApiKey('opencode');
  final openCodeUrl = openCodeCfg?.baseUrl ?? 'https://opencode.ai/zen/v1';
  options.add(_ModelSwitchOption(
    label: '${AnsiColors.brightMagenta}⚡ OpenCode Zen (opencode.ai)${AnsiColors.reset} : Escolher modelo [qwen, deepseek, claude, gpt...] (Atual: $openCodeModel)',
    provider: 'opencode',
    model: openCodeModel,
    apiKey: openCodeKey,
    baseUrl: openCodeUrl,
    isLocal: false,
    aliases: ['5', 'opencode', 'opencode.ai', 'zen'],
  ));

  // 6. Servidor Local / LAN Customizado (LocalAI / vLLM / LMStudio / Ollama LAN)
  final localAiCfg = aiConfig?.providers['local_ai'] ?? aiConfig?.providers['lan_ai'];
  final localAiModel = localAiCfg?.defaultModel ?? 'local-model';
  final localAiUrl = localAiCfg?.baseUrl ?? 'http://localhost:8080';
  options.add(_ModelSwitchOption(
    label: '${AnsiColors.brightWhite}🖥️ Servidor Local (LAN)${AnsiColors.reset}     : $localAiModel [RAG Ativo / LAN] ($localAiUrl)',
    provider: 'local_ai',
    model: localAiModel,
    baseUrl: localAiUrl,
    isLocal: true,
    aliases: ['6', 'local_ai', 'localai', 'lan_ai'],
  ));

  return options;
}

Future<_ModelSwitchOption?> _promptOllamaModelSelection({
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
      stdout.writeln('${AnsiColors.brightGreen}${onlineModels.length} modelo(s) detectado(s)!${AnsiColors.reset}\n');
    } else {
      stdout.writeln('${AnsiColors.brightYellow}Ollama offline ou inacessível em $localUrl.${AnsiColors.reset}');
      stdout.writeln('💡 Está em outra máquina na rede? Digite ${AnsiColors.bold}[u]${AnsiColors.reset} para definir IP/porta.\n');
    }

    print('${AnsiColors.bold}Modelos disponíveis no seu Ollama:${AnsiColors.reset}');
    for (var i = 0; i < allOllamaModels.length; i++) {
      final m = allOllamaModels[i];
      final isCurrent = m == currentModel;
      final check = isCurrent ? ' ${AnsiColors.brightGreen}★ (Ativo)${AnsiColors.reset}' : '';
      print('  [${i + 1}] $m$check');
    }
    print('  [u] 🌐 Alterar IP / URL do Ollama na rede (atual: $localUrl)');

    print('────────────────────────────────────────────────────────────────────────');
    stdout.write('Escolha um modelo [1-${allOllamaModels.length}], [u] para IP/URL (Enter para manter "$currentModel"): ');
    final input = stdin.readLineSync()?.trim();
    if (input == null || input.isEmpty) {
      return _ModelSwitchOption(
        label: '$currentModel (ollama)',
        provider: 'ollama',
        model: currentModel,
        baseUrl: localUrl,
        isLocal: true,
      );
    }

    if (input.toLowerCase() == 'u' || input.toLowerCase() == 'url' || input.toLowerCase() == 'ip') {
      stdout.write('\nDigite o IP ou hostname do Ollama na rede (ex: http://192.168.1.50:11434) [$localUrl]: ');
      final newUrlInput = stdin.readLineSync()?.trim();
      final newUrl = LanAiHelper.normalize(
        newUrlInput == null || newUrlInput.isEmpty ? localUrl : newUrlInput,
        defaultUrl: localUrl,
      );
      localUrl = newUrl;

      if (currentCfg != null) {
        final updatedProviders = Map<String, AiProviderConfigEntity>.from(currentCfg.providers);
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
      print('${AnsiColors.brightGreen}✅ Endereço do Ollama atualizado para: $localUrl${AnsiColors.reset}');
      continue;
    }

    final idx = int.tryParse(input);
    String chosenModel;
    if (idx != null && idx >= 1 && idx <= allOllamaModels.length) {
      chosenModel = allOllamaModels[idx - 1];
    } else {
      chosenModel = input;
    }

    return _ModelSwitchOption(
      label: '$chosenModel (ollama)',
      provider: 'ollama',
      model: chosenModel,
      baseUrl: localUrl,
      isLocal: true,
    );
  }
}

Future<_ModelSwitchOption?> _promptOpenCodeModelSelection({
  required AiConfigModel? aiConfig,
  required String currentModel,
}) async {
  var currentCfg = aiConfig;
  var openCodeCfg = currentCfg?.providers['opencode'];
  var apiKey = openCodeCfg?.apiKey ?? _resolveEnvApiKey('opencode');
  final baseUrl = openCodeCfg?.baseUrl ?? 'https://opencode.ai/zen/v1';

  if (apiKey == null || apiKey.isEmpty) {
    stdout.writeln('\n🔑 ${AnsiColors.bold}Configuração do OpenCode Zen (opencode.ai)${AnsiColors.reset}');
    stdout.writeln('O OpenCode Zen permite acesso a múltiplos modelos de ponta com uma única chave de API.');
    stdout.writeln('Obtenha sua chave em: https://opencode.ai ou https://opencode.ai/zen\n');
    stdout.write('Digite sua chave de API do OpenCode (ou Enter para cancelar): ');
    final keyInput = stdin.readLineSync()?.trim();
    if (keyInput == null || keyInput.isEmpty) {
      print('ℹ️  Configuração cancelada.\n');
      return null;
    }
    apiKey = keyInput;

    if (currentCfg != null) {
      final updatedProviders = Map<String, AiProviderConfigEntity>.from(currentCfg.providers);
      final existingProv = updatedProviders['opencode'];
      updatedProviders['opencode'] = AiProviderConfigModel(
        id: 'opencode',
        apiKey: apiKey,
        baseUrl: baseUrl,
        defaultModel: existingProv?.defaultModel ?? 'qwen3.8-max',
        knownModels: existingProv?.knownModels ?? AiModelCatalogService.defaultModels['opencode'] ?? [],
      );
      final updated = currentCfg.copyWith(providers: updatedProviders);
      AiConfigService().save(updated);
      currentCfg = updated;
      openCodeCfg = updated.providers['opencode'];
    }
    print('${AnsiColors.brightGreen}✅ Chave de API do OpenCode salva em .shepherd/ai_config.yaml!${AnsiColors.reset}\n');
  }

  stdout.write('🔍 Buscando catálogo de modelos no OpenCode Zen ($baseUrl)... ');
  List<String> onlineModels = [];
  try {
    onlineModels = await AiModelCatalogService()
        .fetchOnlineModels(providerId: 'opencode', apiKey: apiKey, baseUrl: baseUrl)
        .timeout(const Duration(seconds: 3));
  } catch (_) {}

  final allModels = <String>{
    ...onlineModels,
    if (openCodeCfg?.defaultModel != null) openCodeCfg!.defaultModel,
    ...?openCodeCfg?.knownModels,
    ...?AiModelCatalogService.defaultModels['opencode'],
  }.toList();

  if (onlineModels.isNotEmpty) {
    stdout.writeln('${AnsiColors.brightGreen}${onlineModels.length} modelo(s) disponível(is)!${AnsiColors.reset}\n');
  } else {
    stdout.writeln('${AnsiColors.gray}Utilizando catálogo padrão do OpenCode Zen.${AnsiColors.reset}\n');
  }

  print('${AnsiColors.bold}Modelos disponíveis no OpenCode Zen:${AnsiColors.reset}');
  for (var i = 0; i < allModels.length; i++) {
    final m = allModels[i];
    final isCurrent = m == currentModel;
    final check = isCurrent ? ' ${AnsiColors.brightGreen}★ (Ativo)${AnsiColors.reset}' : '';
    print('  [${i + 1}] $m$check');
  }
  print('  [k] 🔑 Atualizar chave de API do OpenCode');
  print('  [m] ✍️ Digitar manualmente outro nome de modelo');

  print('────────────────────────────────────────────────────────────────────────');
  stdout.write('Escolha uma opção [1-${allModels.length}], [k] chave, [m] outro (Enter para manter "$currentModel"): ');
  final input = stdin.readLineSync()?.trim();
  if (input == null || input.isEmpty) {
    return _ModelSwitchOption(
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
        final updatedProviders = Map<String, AiProviderConfigEntity>.from(currentCfg.providers);
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
      print('${AnsiColors.brightGreen}✅ Chave de API atualizada com sucesso!${AnsiColors.reset}\n');
    }
  }

  String chosenModel;
  if (input.toLowerCase() == 'm' || input.toLowerCase() == 'outro') {
    stdout.write('\nDigite o ID do modelo no OpenCode (ex: deepseek-v4-pro, qwen3.8-max): ');
    final customModel = stdin.readLineSync()?.trim();
    chosenModel = (customModel != null && customModel.isNotEmpty) ? customModel : currentModel;
  } else {
    final idx = int.tryParse(input);
    if (idx != null && idx >= 1 && idx <= allModels.length) {
      chosenModel = allModels[idx - 1];
    } else {
      chosenModel = input;
    }
  }

  return _ModelSwitchOption(
    label: '$chosenModel (opencode)',
    provider: 'opencode',
    model: chosenModel,
    apiKey: apiKey,
    baseUrl: baseUrl,
    isLocal: false,
  );
}

String _normalizeModelName(String model) {
  final m = model.toLowerCase().trim();
  if (m == 'sonnet 5' || m == 'sonnet-5' || m == 'claude 5' || m == 'claude-5' || m == 'sonnet') {
    return 'claude-sonnet-5';
  }
  if (m == 'sonnet 4.6' || m == 'sonnet-4.6' || m == 'sonnet-4-6' || m == 'claude 4.6' || m == 'claude-4.6') {
    return 'claude-sonnet-4-6';
  }
  if (m == 'flash' || m == 'gemini flash') {
    return 'gemini-2.5-flash';
  }
  if (m == 'pro' || m == 'gemini pro') {
    return 'gemini-2.5-pro';
  }
  return model.trim();
}

_ModelSwitchOption? _selectModelOption(String input, List<_ModelSwitchOption> options, AiConfigModel? aiConfig) {
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
      return _ModelSwitchOption(
        label: '$targetModel (ollama)',
        provider: 'ollama',
        model: targetModel,
        baseUrl: baseUrl,
        isLocal: true,
      );
    }
  }

  // 3. Quick alias normalization for known models (e.g. "sonnet 5" -> "claude-sonnet-5")
  final resolvedModel = _normalizeModelName(clean);
  final isModelAlias = resolvedModel != clean;
  final modelToSearch = isModelAlias ? resolvedModel : clean;

  // 4. Raw provider typed by user (e.g. "claude", "anthropic", "openai", "chat_gpt", "gemini", "ollama")
  if (!isModelAlias) {
    final matchedProvider = _normalizeProvider(clean);
    if (matchedProvider != null) {
      for (final opt in options) {
        if (opt.provider == matchedProvider) {
          return opt;
        }
      }
      final provCfg = aiConfig?.providers[matchedProvider];
      final modelName = provCfg?.defaultModel ?? _defaultModelFor(matchedProvider);
      final key = provCfg?.apiKey ?? _resolveEnvApiKey(matchedProvider);
      final baseUrl = provCfg?.baseUrl;
      final isLocal = matchedProvider == 'ollama' ||
          matchedProvider == 'local_ai' ||
          (baseUrl != null && baseUrl.isNotEmpty && LanAiHelper.isLocalOrLan(baseUrl));

      return _ModelSwitchOption(
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
  final inferred = _inferProviderFromModel(modelToSearch);
  if (inferred != null) {
    final provCfg = aiConfig?.providers[inferred];
    final key = provCfg?.apiKey ?? _resolveEnvApiKey(inferred);
    final baseUrl = provCfg?.baseUrl;
    final isLocal = inferred == 'ollama' ||
        inferred == 'local_ai' ||
        (baseUrl != null && baseUrl.isNotEmpty && LanAiHelper.isLocalOrLan(baseUrl));

    return _ModelSwitchOption(
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
        final key = entry.value.apiKey ?? _resolveEnvApiKey(prov);
        final baseUrl = entry.value.baseUrl;
        final isLocal = prov == 'ollama' ||
            prov == 'local_ai' ||
            (baseUrl != null && baseUrl.isNotEmpty && LanAiHelper.isLocalOrLan(baseUrl));

        return _ModelSwitchOption(
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
    return _ModelSwitchOption(
      label: '$raw (ollama)',
      provider: 'ollama',
      model: raw,
      baseUrl: OllamaUrlHelper.normalize(ollamaCfg?.baseUrl),
      isLocal: true,
    );
  }

  return null;
}

String? _normalizeProvider(String input) {
  final clean = input.trim().toLowerCase();
  if (clean == 'openai' || clean == 'chatgpt' || clean == 'chat_gpt' || clean == 'chat-gpt' || clean == 'gpt') {
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

String? _inferProviderFromModel(String model) {
  final m = model.toLowerCase().trim();
  final norm = _normalizeProvider(m);
  if (norm != null) return norm;

  if (m.startsWith('gpt-') || m.startsWith('gpt4') || m.startsWith('gpt3') ||
      m.startsWith('o1') || m.startsWith('o3') || m.startsWith('text-embedding')) {
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
  if (m.startsWith('llama') || m.startsWith('mistral') || m.startsWith('deepseek') ||
      m.startsWith('qwen') || m.startsWith('phi') || m.startsWith('codellama') ||
      m.startsWith('nomic') || m.startsWith('gemma')) {
    return 'ollama';
  }
  return null;
}

String _defaultModelFor(String provider) {
  switch (provider.toLowerCase()) {
    case 'gemini':
    case 'google':
      return 'gemini-2.5-flash';
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

String? _resolveEnvApiKey(String provider) {
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

String _providerDisplayName(String provider) {
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

String _readWorkspaceContext({required bool includeWorkspace}) {
  const paths = [
    '.shepherd/project.yaml',
    '.shepherd/specs.yaml',
    '.shepherd/skills.yaml',
    '.shepherd/environments.yaml',
    '.shepherd/domains.yaml',
    '.shepherd/mcp.json',
    'devops/domains.yaml',
  ];

  final buffer = StringBuffer();

  if (includeWorkspace) {
    final workspace = WorkspaceManifest.tryLoad();
    if (workspace != null && workspace.projects.isNotEmpty) {
      buffer.writeln('# .shepherd/workspace.yaml');
      buffer.writeln(workspace.toSummary());
      buffer.writeln();
    }
  }

  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync().trim();
    if (content.isEmpty) continue;
    buffer.writeln('# $path');
    buffer.writeln(content);
    buffer.writeln();
  }
  return buffer.toString().trim();
}

String _formatSystemPreamble({
  required String workingDir,
  required bool isLocal,
}) {
  final buffer = StringBuffer();
  buffer.writeln('Você é o assistente de inteligência artificial integrado ao Shepherd CLI.');
  buffer.writeln('Você está operando diretamente no contexto do projeto em: $workingDir.');
  buffer.writeln('Você tem acesso aos arquivos do projeto indexados via RAG local, menções com @arquivo e ferramentas MCP.');
  buffer.writeln('Quando o desenvolvedor solicitar auxílio ou modificações, forneça respostas técnicas precisas alinhadas com o ecossistema e a arquitetura do projeto.');
  buffer.writeln();
  return buffer.toString();
}

String _formatModePrompt(String mode) {
  if (mode == 'plan') {
    return '--- Diretrizes do Modo PLAN (Planejamento) ---\n'
        'Você está no MODO DE PLANEJAMENTO (PLAN MODE).\n'
        'Elabore um plano arquitetural detalhado e estruturado para a solicitação:\n'
        '1. Objetivo e Escopo da tarefa;\n'
        '2. Análise de Arquitetura e Dependências;\n'
        '3. Arquivos a Criar ou Modificar (com caminhos exatos no projeto);\n'
        '4. Passo a Passo de Implementação e Validações;\n'
        '5. Riscos e Medidas de Contingência.\n'
        'Importante: Não execute alterações de escrita nem gere blocos de patch ainda. Foque no plano detalhado para alinhamento.\n\n';
  } else if (mode == 'auto') {
    return '--- Diretrizes do Modo AUTO (Execução Autônoma) ---\n'
        'Você está no MODO AUTÔNOMO (AUTO MODE).\n'
        'Quando propor código ou soluções, forneça os arquivos completos usando a sintaxe de patch do Shepherd:\n'
        '```linguagem\n'
        '// FILE: caminho/do/arquivo.ext\n'
        'conteúdo completo do arquivo\n'
        '```\n'
        'O Shepherd CLI aplicará as alterações de arquivos diretamente no projeto.\n\n';
  }
  return '';
}

String _formatTierPrompt(String tier) {
  if (tier == 'deep') {
    return '--- Diretrizes de Raciocínio DEEP ---\n'
        'Analise com máxima profundidade técnica, avaliando casos de borda, impacto em performance, modularidade e padrões de projeto.\n\n';
  }
  return '';
}

void _printModelFooter({
  required String provider,
  required String model,
  required String tier,
  String? mode,
  int? latencyMs,
  AiTokenUsageEntity? tokens,
  int? tokensUsed,
  String? ragStatus,
}) {
  final latencyStr = latencyMs != null ? ' | Latência: ${latencyMs}ms' : '';
  final modeStr = mode != null ? ' | Modo: ${AnsiColors.brightCyan}$mode${AnsiColors.gray}' : '';
  String tokensStr = '';
  if (tokens != null) {
    final typeBadge = tokens.isLocal
        ? '${AnsiColors.brightGreen}${tokens.typeLabel}${AnsiColors.gray}'
        : '${AnsiColors.brightYellow}${tokens.typeLabel}${AnsiColors.gray}';
    tokensStr = ' | Tokens: ${tokens.totalTokens} [${tokens.promptTokens}p+${tokens.completionTokens}c] ($typeBadge)';
  } else if (tokensUsed != null) {
    tokensStr = ' | Tokens: $tokensUsed';
  }
  final ragStr = ragStatus != null ? ' | RAG: ${AnsiColors.brightGreen}$ragStatus${AnsiColors.gray}' : '';
  print('\n${AnsiColors.gray}────────────────────────────────────────────────────────────────────────${AnsiColors.reset}');
  print('${AnsiColors.gray}🧠 Motor: ${AnsiColors.brightCyan}$model${AnsiColors.gray} | Provedor: ${AnsiColors.bold}$provider${AnsiColors.reset}${AnsiColors.gray}$modeStr | Tier: $tier$ragStr$latencyStr$tokensStr${AnsiColors.reset}');
  print('${AnsiColors.gray}────────────────────────────────────────────────────────────────────────${AnsiColors.reset}\n');
}

String formatAiSystemPreamble({required String workingDir, required bool isLocal}) =>
    _formatSystemPreamble(workingDir: workingDir, isLocal: isLocal);
String formatAiModePrompt(String mode) => _formatModePrompt(mode);
String formatAiTierPrompt(String tier) => _formatTierPrompt(tier);
