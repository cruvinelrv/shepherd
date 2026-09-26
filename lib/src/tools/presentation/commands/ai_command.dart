import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:yaml/yaml.dart';
import '../../domain/services/ai_config_service.dart';
import '../../domain/services/shepherd_platform_ai_service.dart';
import '../../domain/services/workspace_manifest_service.dart';
import 'ai_config_command.dart';

/// Sends a prompt to Shepherd Intelligence via the Shepherd Platform AI Gateway,
/// supporting execution modes (fast, plan, auto) and tiers (fast, deep).
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

  final argsPrompt = argResults.rest.join(' ');
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
          stdout.write('\nDeseja aprovar e executar este plano? [S/n]: ');
          final confirm = stdin.readLineSync()?.trim().toLowerCase();
          if (confirm == 's' || confirm == 'sim' || confirm == 'y' || confirm == 'yes') {
            print('\n⏳ Executando plano aprovado...');
            final approveRes = await platformService.approvePlan(taskId: res.taskId!);
            print('✅ Plano concluído com sucesso!');
            if (approveRes['result'] != null) {
              print('\n${approveRes['result']}');
            }
          } else {
            print('Plano cancelado.');
          }
        } else {
          print(res.text ?? 'Plano processado.');
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

      await for (final chunk in responseStream) {
        stdout.write(chunk.text);
      }
      stdout.writeln();
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

    final message = (firstMessage && workspaceContext.isNotEmpty)
        ? '--- Contexto do Workspace Shepherd ---\n$workspaceContext\n\n$question'
        : question;
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
        print('\n$answer\n');
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
        await for (final chunk in responseStream) {
          stdout.write(chunk.text);
        }
        stdout.writeln('\n');
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
    '.shepherd/environments.yaml',
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
