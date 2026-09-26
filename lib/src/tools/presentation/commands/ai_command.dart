import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:yaml/yaml.dart';
import '../../domain/services/ai_config_service.dart';
import '../../domain/services/ai_file_patch_service.dart';
import '../../domain/services/ai_local_context_service.dart';
import '../../domain/services/shepherd_platform_ai_service.dart';
import '../../domain/services/workspace_manifest_service.dart';
import '../../../utils/ansi_colors.dart';
import 'ai_config_command.dart';

/// Sends a prompt to Shepherd Intelligence via the Shepherd Platform AI Gateway,
/// supporting execution modes (fast, plan, auto), tiers (fast, deep), local file reading and safe patching.
Future<void> runAiCommand(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'model',
      abbr: 'm',
      defaultsTo: 'gemini-3.8-flash',
      help: 'Modelo de IA a ser utilizado.',
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
      help: 'Modo de execução: fast (direto), plan (planejamento prévio) ou auto (autônomo).',
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
      help: 'Atalho para --mode plan (mostra os passos e pede aprovação antes de agir).',
    )
    ..addFlag(
      'auto',
      negatable: false,
      help: 'Atalho para --mode auto (planeja e executa autonomamente).',
    )
    ..addFlag(
      'deep',
      negatable: false,
      help: 'Atalho para --tier deep (utiliza modelo com capacidade avançada de raciocínio).',
    );
  parser.addCommand('config');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print('❌ Error: ${e.toString()}');
    print(
        'Usage: shepherd ai "seu prompt" [--mode fast|plan|auto] [--tier fast|deep] [--scope project|workspace]');
    print('       shepherd ai config');
    return;
  }

  if (argResults.command?.name == 'config') {
    await runAiConfigCommand();
    return;
  }

  final sessionToken = _getGlobalToken();
  final aiConfig = AiConfigService().load();
  final localApiKey = aiConfig?.apiKey ?? Platform.environment['GEMINI_API_KEY'];

  if ((sessionToken == null || sessionToken.isEmpty) && (localApiKey == null || localApiKey.isEmpty)) {
    stderr.writeln(
        'Erro: você precisa estar autenticado na Shepherd Platform para usar o shepherd ai.');
    stderr.writeln('Rode `shepherd login` para autenticar sua conta.');
    exitCode = 1;
    return;
  }

  var mode = argResults['mode'] as String;
  if (argResults['plan'] == true) mode = 'plan';
  if (argResults['auto'] == true) mode = 'auto';

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

  // Verifica se há entrada vindo de um pipe Unix (ex: cat log.txt | shepherd ai)
  if (!stdin.hasTerminal) {
    stdinContent = await utf8.decodeStream(stdin);
  }

  final scope = argResults['scope'] as String;
  final workspaceContext =
      _readWorkspaceContext(includeWorkspace: scope == 'workspace');

  // Nenhuma pergunta na linha de comando nem em um pipe, mas rodando num
  // terminal de verdade: entra em modo de conversa interativo.
  if (argsPrompt.isEmpty && stdinContent.isEmpty) {
    if (stdin.hasTerminal) {
      await _runInteractiveChat(
        sessionToken: sessionToken,
        localApiKey: localApiKey,
        modelName: argResults['model'] as String,
        workspaceContext: workspaceContext,
        tier: tier,
      );
      return;
    }
    print('Uso:');
    print('  shepherd ai "seu prompt"');
    print('  shepherd ai "analise o código @lib/main.dart"');
    print('  shepherd ai -f pubspec.yaml "qual dependência está desatualizada?"');
    print('  shepherd ai --plan "refatore a camada de auth"');
    print('  shepherd ai --deep "analise a arquitetura DDD"');
    print('  cat arquivo.txt | shepherd ai "resuma"');
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

  // 1. Rota Primária: Shepherd Platform AI Gateway (Shepherd Intelligence)
  if (sessionToken != null && sessionToken.isNotEmpty) {
    final platformService = ShepherdPlatformAiService();

    try {
      if (mode == 'plan') {
        print('🧠 Analisando projeto e gerando plano de ação (Shepherd Intelligence)...\n');
        final res = await platformService.generate(
          goal: finalPrompt,
          mode: 'plan',
          tier: tier,
          workspaceContext: workspaceContext,
        );

        if (res.isAwaitingPlanApproval && res.steps.isNotEmpty) {
          print('📋 Plano Proposto:');
          for (var i = 0; i < res.steps.length; i++) {
            print('  [${i + 1}] ${res.steps[i]}');
          }
          _printModelFooter(
            provider: res.provider ?? 'Shepherd Platform',
            model: res.modelUsed ?? (tier == 'deep' ? 'gemini-1.5-pro' : 'gemini-2.5-flash'),
            tier: tier,
            latencyMs: res.latencyMs,
            tokensUsed: res.tokensUsed,
          );

          final fileActions = AiFilePatchService.extractActions(res.text ?? '');

          stdout.write('\nDeseja aprovar e executar este plano? [S/n]: ');
          final confirm = stdin.readLineSync()?.trim().toLowerCase();
          if (confirm == null || confirm.isEmpty || confirm == 's' || confirm == 'sim' || confirm == 'y' || confirm == 'yes') {
            print('\n⏳ Executando plano aprovado...');
            final approveRes = await platformService.approvePlan(taskId: res.taskId!);
            print('✅ Plano concluído com sucesso!');
            if (approveRes['result'] != null) {
              print('\n${approveRes['result']}');
            }
            if (fileActions.isNotEmpty) {
              await AiFilePatchService.promptAndApply(fileActions);
            }
          } else {
            print('Plano cancelado.');
          }
        } else {
          print(res.text ?? 'Plano processado.');
          _printModelFooter(
            provider: res.provider ?? 'Shepherd Platform',
            model: res.modelUsed ?? (tier == 'deep' ? 'gemini-1.5-pro' : 'gemini-2.5-flash'),
            tier: tier,
            latencyMs: res.latencyMs,
            tokensUsed: res.tokensUsed,
          );
          final fileActions = AiFilePatchService.extractActions(res.text ?? '');
          if (fileActions.isNotEmpty) {
            await AiFilePatchService.promptAndApply(fileActions);
          }
        }
        return;
      }

      if (mode == 'auto') {
        print('🚀 Executando objetivo no modo autônomo (Shepherd Intelligence)...\n');
        final res = await platformService.generate(
          goal: finalPrompt,
          mode: 'auto',
          tier: tier,
          workspaceContext: workspaceContext,
        );
        if (res.steps.isNotEmpty) {
          print('Passos executados:');
          for (final step in res.steps) {
            print('  ✅ $step');
          }
        }
        if (res.text != null && res.text!.isNotEmpty) {
          print('\n${res.text}');
        }
        _printModelFooter(
          provider: res.provider ?? 'Shepherd Platform',
          model: res.modelUsed ?? (tier == 'deep' ? 'gemini-1.5-pro' : 'gemini-2.5-flash'),
          tier: tier,
          latencyMs: res.latencyMs,
          tokensUsed: res.tokensUsed,
        );
        final fileActions = AiFilePatchService.extractActions(res.text ?? '');
        if (fileActions.isNotEmpty) {
          print('⚡ Aplicando modificações de arquivos...');
          await AiFilePatchService.promptAndApply(fileActions, autoApprove: true);
        }
        return;
      }

      // Modo Fast (Padrão)
      final res = await platformService.generate(
        goal: finalPrompt,
        mode: 'fast',
        tier: tier,
        workspaceContext: workspaceContext,
      );
      if (res.text != null) {
        print(res.text);
      }
      _printModelFooter(
        provider: res.provider ?? 'Shepherd Platform',
        model: res.modelUsed ?? (tier == 'deep' ? 'gemini-1.5-pro' : 'gemini-2.5-flash'),
        tier: tier,
        latencyMs: res.latencyMs,
        tokensUsed: res.tokensUsed,
      );

      final fileActions = AiFilePatchService.extractActions(res.text ?? '');
      if (fileActions.isNotEmpty) {
        await AiFilePatchService.promptAndApply(fileActions);
      }
      return;
    } catch (e) {
      if (localApiKey == null || localApiKey.isEmpty) {
        stderr.writeln('\n❌ Erro ao comunicar com a Shepherd Platform: $e');
        exitCode = 1;
        return;
      }
      stderr.writeln('\n⚠️  Shepherd Platform AI indisponível ($e). Usando fallback local...\n');
    }
  }

  // 2. Fallback: Provedor Local se configurado
  if (localApiKey != null && localApiKey.isNotEmpty) {
    final modelName = argResults['model'] as String;
    final model = GenerativeModel(model: modelName, apiKey: localApiKey);
    try {
      final responseStream = model.generateContentStream([
        Content.text(finalPrompt),
      ]);

      final outputBuffer = StringBuffer();
      await for (final chunk in responseStream) {
        stdout.write(chunk.text);
        if (chunk.text != null) outputBuffer.write(chunk.text);
      }
      stdout.writeln();

      _printModelFooter(
        provider: 'Google Gemini (Local)',
        model: modelName,
        tier: tier,
      );

      final fileActions = AiFilePatchService.extractActions(outputBuffer.toString());
      if (fileActions.isNotEmpty) {
        await AiFilePatchService.promptAndApply(fileActions);
      }
    } catch (e) {
      stderr.writeln('\nErro ao comunicar com a IA: $e');
      exitCode = 1;
    }
  }
}

const _exitWords = ['sair', 'exit', 'quit'];

/// `shepherd ai` with no prompt, run from a real terminal — a REPL that
/// keeps conversation history between turns via the SDK's own ChatSession
/// (so the AI remembers what was said earlier in the session), instead of
/// the single-shot call the CLI-argument form makes. The workspace context
/// only needs to ride along on the first message — the chat history covers
/// every turn after that.
Future<void> _runInteractiveChat({
  String? sessionToken,
  String? localApiKey,
  required String modelName,
  required String workspaceContext,
  String tier = 'fast',
}) async {
  print('\n💬 Shepherd AI — modo interativo (Shepherd Platform)');
  print('Digite sua pergunta. "sair" (ou Ctrl+D) para encerrar.\n');

  final history = <Map<String, String>>[];
  var firstMessage = true;

  final platformService =
      sessionToken != null ? ShepherdPlatformAiService() : null;
  final localModel = (localApiKey != null && localApiKey.isNotEmpty)
      ? GenerativeModel(model: modelName, apiKey: localApiKey)
      : null;
  final localChat = localModel?.startChat();

  while (true) {
    stdout.write('> ');
    final input = stdin.readLineSync();
    if (input == null) break; // Ctrl+D / EOF
    final question = input.trim();
    if (question.isEmpty) continue;
    if (_exitWords.contains(question.toLowerCase())) break;

    // Resolve @file mentions in question
    final fileResolution = AiLocalContextService.resolveLocalFiles(prompt: question);
    if (fileResolution.resolvedFiles.isNotEmpty) {
      print('📂 Arquivos anexados: ${AnsiColors.brightGreen}${fileResolution.resolvedFiles.join(', ')}${AnsiColors.reset}');
    }
    if (fileResolution.missingFiles.isNotEmpty) {
      print('⚠️  Arquivos não encontrados: ${AnsiColors.brightYellow}${fileResolution.missingFiles.join(', ')}${AnsiColors.reset}');
    }

    final enrichedQuestion = fileResolution.enrichedPrompt;
    final message = (firstMessage && workspaceContext.isNotEmpty)
        ? '--- Contexto do Workspace Shepherd ---\n$workspaceContext\n\n$enrichedQuestion'
        : enrichedQuestion;
    firstMessage = false;

    if (platformService != null) {
      try {
        final res = await platformService.generate(
          goal: message,
          mode: 'fast',
          tier: tier,
          history: history,
        );
        final answer = res.text ?? '';
        print('\n$answer');
        _printModelFooter(
          provider: res.provider ?? 'Shepherd Platform',
          model: res.modelUsed ?? (tier == 'deep' ? 'gemini-1.5-pro' : 'gemini-2.5-flash'),
          tier: tier,
          latencyMs: res.latencyMs,
          tokensUsed: res.tokensUsed,
        );

        final fileActions = AiFilePatchService.extractActions(answer);
        if (fileActions.isNotEmpty) {
          await AiFilePatchService.promptAndApply(fileActions);
        }

        history.add({'role': 'user', 'content': question});
        history.add({'role': 'assistant', 'content': answer});
        continue;
      } catch (e) {
        if (localChat == null) {
          stderr.writeln('\nErro ao comunicar com a Shepherd Platform: $e\n');
          continue;
        }
        print('⚠️  Usando fallback local...\n');
      }
    }

    if (localChat != null) {
      try {
        final responseStream = localChat.sendMessageStream(Content.text(message));
        final chatBuffer = StringBuffer();
        await for (final chunk in responseStream) {
          stdout.write(chunk.text);
          if (chunk.text != null) chatBuffer.write(chunk.text);
        }
        stdout.writeln();

        _printModelFooter(
          provider: 'Google Gemini (Local)',
          model: modelName,
          tier: tier,
        );

        final fileActions = AiFilePatchService.extractActions(chatBuffer.toString());
        if (fileActions.isNotEmpty) {
          await AiFilePatchService.promptAndApply(fileActions);
        }
      } catch (e) {
        stderr.writeln('\nErro ao comunicar com o Gemini: $e\n');
      }
    }
  }

  print('Até mais!');
}

/// Reads the session token saved by `shepherd login`, same file/shape used
/// by TelemetrySyncService._getGlobalToken.
String? _getGlobalToken() {
  final sessionFile = File('.shepherd/session.yaml');
  if (!sessionFile.existsSync()) return null;
  final content = sessionFile.readAsStringSync();
  if (content.trim().isEmpty) return null;
  final loaded = loadYaml(content);
  if (loaded is YamlMap && loaded.containsKey('token')) {
    return loaded['token'] as String;
  }
  return null;
}

/// Collects the local Shepherd workspace config (populated by `shepherd
/// login`/`init`/`pull`, or by Shepherd Studio) so the AI has real project
/// context instead of a bare prompt. [includeWorkspace] controls whether the
/// other projects listed in `.shepherd/workspace.yaml` are in scope
/// (`--scope workspace`) or the AI only sees the current project
/// (`--scope project`, the default).
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

  // workspace.yaml gets a summary, not a raw dump — Studio's format nests
  // projects by category, which reads worse to an LLM than one line each.
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

/// Prints a clear visual footer showing the active LLM engine, provider, tier, and latency/tokens.
void _printModelFooter({
  required String provider,
  required String model,
  required String tier,
  int? latencyMs,
  int? tokensUsed,
}) {
  final latencyStr = latencyMs != null ? ' | Latência: ${latencyMs}ms' : '';
  final tokensStr = tokensUsed != null ? ' | Tokens: $tokensUsed' : '';
  print('\n${AnsiColors.gray}────────────────────────────────────────────────────────────────────────${AnsiColors.reset}');
  print('${AnsiColors.gray}🧠 Motor: ${AnsiColors.brightCyan}$model${AnsiColors.gray} | Provedor: ${AnsiColors.bold}$provider${AnsiColors.reset}${AnsiColors.gray} | Tier: $tier$latencyStr$tokensStr${AnsiColors.reset}');
  print('${AnsiColors.gray}────────────────────────────────────────────────────────────────────────${AnsiColors.reset}\n');
}

