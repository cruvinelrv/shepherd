import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import '../../domain/entities/ai_token_usage_entity.dart';
import '../../domain/services/ai_config_service.dart';
import '../../domain/services/ai_direct_inference_service.dart';
import '../../domain/services/ai_file_patch_service.dart';
import '../../domain/services/ai_local_context_service.dart';
import '../../domain/services/shepherd_platform_ai_service.dart';
import '../../domain/services/workspace_manifest_service.dart';
import '../../../utils/ansi_colors.dart';
import 'ai_config_command.dart';

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
    );
  final configCmd = parser.addCommand('config');
  configCmd.addFlag('sync', abbr: 's', negatable: false, help: 'Sincroniza catálogo de modelos online.');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print('❌ Erro: ${e.toString()}');
    print(
        'Uso: shepherd ai "seu prompt" [-m modelo] [-p provedor] [--tier fast|deep] [--file caminho]');
    print('     shepherd ai config [--sync]');
    return;
  }

  if (argResults.command?.name == 'config') {
    await runAiConfigCommand(argResults.command!.arguments);
    return;
  }

  final aiConfig = AiConfigService().load();

  // Resolução inteligente de provedor e modelo
  String? resolvedProvider = argResults['provider'] as String?;
  String? resolvedModel = argResults['model'] as String?;

  if (resolvedProvider == null && resolvedModel != null) {
    resolvedProvider = _inferProviderFromModel(resolvedModel);
  }

  resolvedProvider ??= aiConfig?.activeProvider ?? 'gemini';

  final providerConfig = aiConfig?.providers[resolvedProvider.toLowerCase()];
  resolvedModel ??= aiConfig?.activeModel ?? providerConfig?.defaultModel ?? _defaultModelFor(resolvedProvider);

  final apiKey = providerConfig?.apiKey ?? _resolveEnvApiKey(resolvedProvider);
  final baseUrl = providerConfig?.baseUrl;

  final hasDirectAccess = (resolvedProvider.toLowerCase() == 'ollama') ||
      (apiKey != null && apiKey.isNotEmpty);

  // Se não tem configuração direta e não há gateway customizado
  final customGateway = Platform.environment['SHEPHERD_AI_GATEWAY_URL'];
  if (!hasDirectAccess && (customGateway == null || customGateway.isEmpty)) {
    stderr.writeln('\n❌ Provedor "$resolvedProvider" não configurado.');
    stderr.writeln('Execute `shepherd ai config` para configurar seu modelo e chave de API.');
    stderr.writeln('Ou defina uma variável de ambiente (ex: export GEMINI_API_KEY="sua_chave").\n');
    exitCode = 1;
    return;
  }

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
      );
      return;
    }
    print('Uso:');
    print('  shepherd ai "seu prompt"');
    print('  shepherd ai "analise o código @lib/main.dart"');
    print('  shepherd ai -f pubspec.yaml "quais dependências estão listadas?"');
    print('  shepherd ai -m gpt-4o "analise a arquitetura"');
    print('  shepherd ai -m llama3.1 "gere um teste"');
    print('  shepherd ai              # modo de conversa interativo');
    return;
  }

  final buffer = StringBuffer();
  if (workspaceContext.isNotEmpty) {
    buffer.writeln('--- Contexto do Workspace Shepherd ---');
    buffer.writeln(workspaceContext);
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
    if (hasFiles && hasWorkspace) {
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

    final fileActions = AiFilePatchService.extractActions(outputBuffer.toString());
    if (fileActions.isNotEmpty) {
      await AiFilePatchService.promptAndApply(fileActions);
    }
  } catch (e) {
    stderr.writeln('\n❌ Erro na execução direta com $resolvedProvider: $e\n');
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
}) async {
  const exitWords = {'exit', 'sair', 'quit', 'q'};
  final history = <Map<String, String>>[];
  final inferenceService = AiDirectInferenceService();

  print('\n${AnsiColors.bold}Shepherd AI — Modo Interativo Direto${AnsiColors.reset}');
  print('────────────────────────────────────────────────────────────────────────');
  final ragInfo = workspaceContext.isNotEmpty ? 'Local (Workspace Ativo)' : 'Local';
  print('🧠 Motor: ${AnsiColors.brightCyan}$modelName${AnsiColors.reset} | Provedor: ${AnsiColors.brightGreen}${_providerDisplayName(provider)}${AnsiColors.reset} | RAG: ${AnsiColors.brightGreen}$ragInfo${AnsiColors.reset}');
  print('Digite sua pergunta ou use @arquivo para anexar contexto.');
  print('Para sair, digite "sair", "exit" ou pressione Ctrl+C.\n');

  var firstMessage = true;

  while (true) {
    stdout.write('> ');
    final input = stdin.readLineSync();
    if (input == null) break;
    final question = input.trim();
    if (question.isEmpty) continue;
    if (exitWords.contains(question.toLowerCase())) break;

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
        provider: provider,
        model: modelName,
        apiKey: apiKey,
        baseUrl: baseUrl,
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
      if (hasFiles && hasWorkspace) {
        chatRagStatus = 'Local (${fileResolution.resolvedFiles.length} arqs + Workspace)';
      } else if (hasFiles) {
        chatRagStatus = 'Local (${fileResolution.resolvedFiles.length} arqs)';
      } else if (hasWorkspace) {
        chatRagStatus = 'Local (Workspace)';
      } else {
        chatRagStatus = 'Desativado';
      }

      _printModelFooter(
        provider: _providerDisplayName(provider),
        model: modelName,
        tier: tier,
        latencyMs: stopwatch.elapsedMilliseconds,
        ragStatus: chatRagStatus,
        tokens: tokenUsage,
      );

      final answer = answerBuffer.toString();
      history.add({'role': 'user', 'content': question});
      history.add({'role': 'assistant', 'content': answer});

      final fileActions = AiFilePatchService.extractActions(answer);
      if (fileActions.isNotEmpty) {
        await AiFilePatchService.promptAndApply(fileActions);
      }
    } catch (e) {
      stderr.writeln('\n❌ Erro ao comunicar com $provider: $e\n');
    }
  }

  print('\nAté mais!');
}

String _inferProviderFromModel(String model) {
  final m = model.toLowerCase();
  if (m.startsWith('gpt-') || m.startsWith('o1') || m.startsWith('o3')) return 'openai';
  if (m.startsWith('claude-')) return 'anthropic';
  if (m.startsWith('llama') || m.startsWith('mistral') || m.startsWith('deepseek') || m.startsWith('qwen')) {
    return 'ollama';
  }
  return 'gemini';
}

String _defaultModelFor(String provider) {
  switch (provider.toLowerCase()) {
    case 'gemini':
      return 'gemini-2.5-flash';
    case 'openai':
      return 'gpt-4o';
    case 'anthropic':
      return 'claude-3-7-sonnet';
    case 'ollama':
      return 'llama3.1';
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
      return 'Ollama (Local)';
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
