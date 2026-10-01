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
import '../../data/models/ai_vector_chunk_model.dart';
import '../../../utils/ai_i18n_helper.dart';
import '../../../utils/ansi_colors.dart';
import 'ai_config_command.dart';
import 'ai_index_command.dart';

/// Executa prompts do Shepherd AI diretamente contra o provedor configurado
/// (Google Gemini, OpenAI, Anthropic ou Ollama local), com suporte a múltiplos arquivos e modo interativo.
Future<void> runAiCommand(List<String> arguments) async {
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

  // Resolução de perfil multilíngue (EN / PT / ES)
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

  // Resolução inteligente de provedor e modelo
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

  // Se não tem configuração direta e não há gateway customizado
  final customGateway = Platform.environment['SHEPHERD_AI_GATEWAY_URL'];
  if (!hasDirectAccess && (customGateway == null || customGateway.isEmpty)) {
    stderr.writeln('\n❌ Provedor "$resolvedProvider" não configurado.');
    stderr.writeln('Execute `shepherd ai config` para configurar seu modelo e chave de API.');
    stderr.writeln('Ou defina uma variável de ambiente (ex: export GEMINI_API_KEY="sua_chave").\n');
    exitCode = 1;
    return;
  }

  // RAG: Ativo por padrão se o modelo/provedor for local (gratuito e sem custo de tokens).
  // Desativado por padrão se for modelo em nuvem/pago (para evitar consumo excessivo de tokens de API).
  // Se o usuário passar --rag ou --no-rag explicitamente, honra a escolha.
  final bool ragExplicitlyProvided = argResults.wasParsed('rag');
  final bool useRag = ragExplicitlyProvided ? (argResults['rag'] as bool) : isLocalProvider;

  var tier = argResults['tier'] as String;
  if (argResults['deep'] == true) tier = 'deep';

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
          ragContext = ragService.formatRagContext(vectorMatches);
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
  if (workspaceContext.isNotEmpty) {
    buffer.writeln('--- Contexto do Workspace Shepherd ---');
    buffer.writeln(workspaceContext);
    buffer.writeln();
  }
  if (ragContext.isNotEmpty) {
    buffer.writeln(ragContext);
    buffer.writeln();
  }
  if (argsPrompt.isNotEmpty) {
    buffer.writeln(argsPrompt);
  }
  if (stdinContent.isNotEmpty) {
    if (argsPrompt.isNotEmpty) buffer.writeln('\n--- Entrada (stdin) ---');
    buffer.writeln(stdinContent);
  }

  final finalPrompt = buffer.toString().trim();

  // Execução via Gateway customizado (se configurado explicitamente via env)
  if (customGateway != null && customGateway.isNotEmpty) {
    final platformService = ShepherdPlatformAiService();
    try {
      final res = await platformService.generate(
        goal: finalPrompt,
        mode: argResults['mode'] as String,
        tier: tier,
        workspaceContext: workspaceContext,
      );
      if (res.text != null) print(res.text);
      _printModelFooter(
        provider: 'Shepherd Gateway ($customGateway)',
        model: res.modelUsed ?? resolvedModel,
        tier: tier,
        latencyMs: res.latencyMs,
        tokensUsed: res.tokensUsed,
      );
      return;
    } catch (e) {
      stderr.writeln('⚠️ Gateway customizado falhou: $e. Recorrendo à execução direta...');
    }
  }

  // Execução Direta (BYOK / Local)
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
    await for (final chunk in responseStream) {
      stdout.write(chunk);
      outputBuffer.write(chunk);
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
      latencyMs: stopwatch.elapsedMilliseconds,
      ragStatus: ragStatus,
      tokens: tokenUsage,
    );

    unawaited(AiTelemetryService().sendAiTelemetry(
      provider: resolvedProvider,
      model: resolvedModel,
      durationMs: stopwatch.elapsedMilliseconds,
      tokens: tokenUsage,
      ragResultCount: vectorMatches.length + fileResolution.resolvedFiles.length + (workspaceContext.isNotEmpty ? 1 : 0),
    ));

    final fileActions = AiFilePatchService.extractActions(outputBuffer.toString());
    if (fileActions.isNotEmpty) {
      await AiFilePatchService.promptAndApply(fileActions);
    }
  } catch (e) {
    stderr.writeln('\n❌ Erro na execução direta com $resolvedProvider: $e\n');
    if (resolvedProvider == 'ollama' || e.toString().contains('11434') || e.toString().contains('Connection refused')) {
      stderr.writeln('💡 O serviço do Ollama não está ativo em localhost:11434.');
      stderr.writeln('   • Para rodar localmente: inicie o Ollama com `ollama serve` em outro terminal.');
      stderr.writeln('   • Para voltar para modelos em nuvem: use `shepherd ai model gemini` ou `shepherd ai --tier fast`.\n');
    }
    exitCode = 1;
  }
}

/// Modo de chat interativo direto
Future<void> _runInteractiveChat({
  required String provider,
  required String modelName,
  String? apiKey,
  String? baseUrl,
  required String workspaceContext,
  required String tier,
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

  print('\n${AnsiColors.bold}Shepherd AI — Modo Interativo Direto${AnsiColors.reset}');
  print('────────────────────────────────────────────────────────────────────────');
  final ragStatusStr = AiI18nHelper.ragStatusLabel(enabled: ragEnabled, isLocal: currentIsLocal);
  print('🧠 Motor: ${AnsiColors.brightCyan}$currentModelName${AnsiColors.reset} | Provedor: ${AnsiColors.brightGreen}${_providerDisplayName(currentProvider)}${AnsiColors.reset} | RAG: ${AnsiColors.brightGreen}$ragStatusStr${AnsiColors.reset}');
  if (!ragEnabled && !currentIsLocal && !ragExplicitlyProvided) {
    print('${AnsiColors.gray}${AiI18nHelper.ragCloudTip()}${AnsiColors.reset}');
  }
  print('Digite sua pergunta ou use @arquivo para anexar contexto.');
  print('Comandos: "/model" para trocar modelo | "/rag on|off" para alternar RAG | "sair" para encerrar.\n');

  var firstMessage = true;
  final chatRagService = AiRagService();

  while (true) {
    stdout.write('> ');
    final input = stdin.readLineSync();
    if (input == null) break;
    final question = input.trim();
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
        } else {
          selected = _selectModelOption(choiceInput, options, aiConfig);
        }
      } else {
        if (arg.toLowerCase() == 'ollama' || arg.toLowerCase() == 'local') {
          selected = await _promptOllamaModelSelection(
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
            apiKey: existingProv?.apiKey ?? currentApiKey,
            baseUrl: existingProv?.baseUrl ?? currentBaseUrl,
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

    final fileResolution = AiLocalContextService.resolveLocalFiles(prompt: question);
    if (fileResolution.resolvedFiles.isNotEmpty) {
      print('📂 Arquivos anexados: ${AnsiColors.brightGreen}${fileResolution.resolvedFiles.join(', ')}${AnsiColors.reset}');
    }
    if (fileResolution.missingFiles.isNotEmpty) {
      print('⚠️  Arquivos não encontrados: ${AnsiColors.brightYellow}${fileResolution.missingFiles.join(', ')}${AnsiColors.reset}');
    }

    final enrichedQuestion = fileResolution.enrichedPrompt;
    final promptBuffer = StringBuffer();

    if (firstMessage && workspaceContext.isNotEmpty) {
      promptBuffer.writeln('--- Contexto do Workspace Shepherd ---');
      promptBuffer.writeln(workspaceContext);
      promptBuffer.writeln();
      firstMessage = false;
    }

    List<AiRagMatchModel> chatRagMatches = [];
    if (ragEnabled && chatRagService.isIndexed) {
      final topK = currentIsLocal ? 3 : 2;
      chatRagMatches = await chatRagService.retrieveRelevantChunks(
        query: enrichedQuestion,
        topK: topK,
      );
      if (chatRagMatches.isNotEmpty) {
        promptBuffer.writeln(chatRagService.formatRagContext(chatRagMatches));
        promptBuffer.writeln();
      }
    }

    if (history.isNotEmpty) {
      promptBuffer.writeln('--- Histórico Recente da Conversa ---');
      for (final h in history.take(6)) {
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
      await for (final chunk in responseStream) {
        stdout.write(chunk);
        answerBuffer.write(chunk);
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
        tier: tier,
        latencyMs: stopwatch.elapsedMilliseconds,
        ragStatus: chatRagStatus,
        tokens: tokenUsage,
      );

      unawaited(AiTelemetryService().sendAiTelemetry(
        provider: currentProvider,
        model: currentModelName,
        durationMs: stopwatch.elapsedMilliseconds,
        tokens: tokenUsage,
        ragResultCount: chatRagMatches.length + fileResolution.resolvedFiles.length + (workspaceContext.isNotEmpty ? 1 : 0),
      ));

      final answer = answerBuffer.toString();
      history.add({'role': 'user', 'content': question});
      history.add({'role': 'assistant', 'content': answer});

      final fileActions = AiFilePatchService.extractActions(answer);
      if (fileActions.isNotEmpty) {
        await AiFilePatchService.promptAndApply(fileActions);
      }
    } catch (e) {
      stderr.writeln('\n❌ Erro ao comunicar com $currentProvider: $e\n');
      if (currentProvider == 'ollama' || e.toString().contains('11434') || e.toString().contains('Connection refused')) {
        stderr.writeln('💡 O serviço do Ollama não está ativo em localhost:11434.');
        stderr.writeln('   • Para rodar localmente: inicie o Ollama com `ollama serve` (ou abra o app Ollama).');
        stderr.writeln('   • Para voltar para modelos em nuvem: digite `medium`, `advanced` ou `/model`.\n');
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
        apiKey: existingProv?.apiKey ?? selected.apiKey,
        baseUrl: existingProv?.baseUrl ?? selected.baseUrl,
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
  final localUrl = ollamaCfg?.baseUrl ?? 'http://localhost:11434';
  options.add(_ModelSwitchOption(
    label: '${AnsiColors.brightGreen}🏠 Local (Ollama)${AnsiColors.reset}       : Escolher modelo do Ollama local [RAG Ativo / Custo Zero] (Atual: $localModel)',
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

  // 5. Servidor Local / LAN Customizado (se configurado)
  final localAiCfg = aiConfig?.providers['local_ai'] ?? aiConfig?.providers['lan_ai'];
  if (localAiCfg != null) {
    final localAiModel = localAiCfg.defaultModel;
    final localAiUrl = localAiCfg.baseUrl ?? 'http://localhost:8080';
    options.add(_ModelSwitchOption(
      label: '${AnsiColors.brightMagenta}🖥️ Servidor Local (LAN)${AnsiColors.reset} : $localAiModel [RAG Ativo / LAN]',
      provider: 'local_ai',
      model: localAiModel,
      baseUrl: localAiUrl,
      isLocal: true,
      aliases: ['5', 'local_ai', 'localai', 'lan_ai'],
    ));
  }

  return options;
}

Future<_ModelSwitchOption?> _promptOllamaModelSelection({
  required AiConfigModel? aiConfig,
  required String currentModel,
}) async {
  final ollamaCfg = aiConfig?.providers['ollama'];
  final localUrl = ollamaCfg?.baseUrl ?? 'http://localhost:11434';

  stdout.write('\n🔍 Buscando modelos disponíveis no Ollama local ($localUrl)... ');
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
    stdout.writeln('${AnsiColors.brightYellow}Ollama offline ou inacessível. Usando modelos conhecidos:${AnsiColors.reset}\n');
  }

  print('${AnsiColors.bold}Modelos disponíveis no seu Ollama:${AnsiColors.reset}');
  for (var i = 0; i < allOllamaModels.length; i++) {
    final m = allOllamaModels[i];
    final isCurrent = m == currentModel;
    final check = isCurrent ? ' ${AnsiColors.brightGreen}★ (Ativo)${AnsiColors.reset}' : '';
    print('  [${i + 1}] $m$check');
  }

  print('────────────────────────────────────────────────────────────────────────');
  stdout.write('Escolha um modelo [1-${allOllamaModels.length}] ou digite o nome (Enter para manter "$currentModel"): ');
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

  // 1. Busca por índice direto [1..N]
  final index = int.tryParse(clean);
  if (index != null && index >= 1 && index <= options.length) {
    return options[index - 1];
  }

  // 2. Comando explícito "ollama <modelo>" ou "local <modelo>"
  if (clean.startsWith('ollama ') || clean.startsWith('local ')) {
    final targetModel = raw.substring(raw.indexOf(' ') + 1).trim();
    if (targetModel.isNotEmpty) {
      final ollamaCfg = aiConfig?.providers['ollama'];
      final baseUrl = ollamaCfg?.baseUrl ?? 'http://localhost:11434';
      return _ModelSwitchOption(
        label: '$targetModel (ollama)',
        provider: 'ollama',
        model: targetModel,
        baseUrl: baseUrl,
        isLocal: true,
      );
    }
  }

  // 3. Normalização de aliases rápidos de modelos conhecidos (ex: "sonnet 5" -> "claude-sonnet-5")
  final resolvedModel = _normalizeModelName(clean);
  final isModelAlias = resolvedModel != clean;
  final modelToSearch = isModelAlias ? resolvedModel : clean;

  // 4. Provedor puro digitado pelo usuário (ex: "claude", "anthropic", "openai", "chat_gpt", "gemini", "ollama")
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

  // 5. Busca exata ou por alias nas opções existentes
  for (final opt in options) {
    if (opt.model.toLowerCase() == modelToSearch ||
        opt.aliases.any((a) => a.toLowerCase() == clean)) {
      return opt;
    }
  }

  // 6. Modelo dinâmico digitado pelo usuário (ex: "qwen2.5-coder:7b", "claude-sonnet-5", "deepseek-r1:8b")
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

  // 7. Se o modelo não tem prefixo padrão, verifica se existe em algum provedor configurado
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

  // 8. Se ainda não achou e parece um modelo Ollama (ex: "qwen2.5-coder:7b", "meu-modelo:latest")
  if (raw.contains(':') || raw.contains('-') || raw.contains('.')) {
    final ollamaCfg = aiConfig?.providers['ollama'];
    return _ModelSwitchOption(
      label: '$raw (ollama)',
      provider: 'ollama',
      model: raw,
      baseUrl: ollamaCfg?.baseUrl ?? 'http://localhost:11434',
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

void _printModelFooter({
  required String provider,
  required String model,
  required String tier,
  int? latencyMs,
  AiTokenUsageEntity? tokens,
  int? tokensUsed,
  String? ragStatus,
}) {
  final latencyStr = latencyMs != null ? ' | Latência: ${latencyMs}ms' : '';
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
  print('${AnsiColors.gray}🧠 Motor: ${AnsiColors.brightCyan}$model${AnsiColors.gray} | Provedor: ${AnsiColors.bold}$provider${AnsiColors.reset}${AnsiColors.gray}$ragStr | Tier: $tier$latencyStr$tokensStr${AnsiColors.reset}');
  print('${AnsiColors.gray}────────────────────────────────────────────────────────────────────────${AnsiColors.reset}\n');
}
