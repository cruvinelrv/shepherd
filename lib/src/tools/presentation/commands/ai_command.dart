import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:yaml/yaml.dart';
import '../../domain/services/ai_config_service.dart';
import '../../domain/services/workspace_manifest_service.dart';
import 'ai_config_command.dart';

/// Sends a prompt (CLI args and/or stdin) to a Gemini model, streaming the response.
Future<void> runAiCommand(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'model',
      abbr: 'm',
      defaultsTo: 'gemini-2.5-flash',
      help: 'Modelo do Gemini a ser utilizado.',
    )
    ..addOption(
      'scope',
      abbr: 's',
      allowed: ['project', 'workspace'],
      defaultsTo: 'project',
      help: 'project: só o diretório atual. workspace: inclui o resumo de '
          'todos os projetos do .shepherd/workspace.yaml.',
    );
  parser.addCommand('config');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print('❌ Error: ${e.toString()}');
    print(
        'Usage: shepherd ai "seu prompt" [--model <modelo>] [--scope project|workspace]');
    print('       shepherd ai config');
    return;
  }

  if (argResults.command?.name == 'config') {
    await runAiConfigCommand();
    return;
  }

  final sessionToken = _getGlobalToken();
  if (sessionToken == null || sessionToken.isEmpty) {
    stderr.writeln(
        'Erro: você precisa estar autenticado para usar o shepherd ai.');
    stderr.writeln('Rode `shepherd login` primeiro.');
    exitCode = 1;
    return;
  }

  final aiConfig = AiConfigService().load();
  final apiKey = aiConfig?.apiKey ?? Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('Erro: nenhuma API Key configurada para o shepherd ai.');
    stderr.writeln('Rode `shepherd ai config`, ou defina GEMINI_API_KEY.');
    exitCode = 1;
    return;
  }

  final argsPrompt = argResults.rest.join(' ');
  String stdinContent = '';

  // Verifica se há entrada vindo de um pipe Unix (ex: cat log.txt | shepherd ai)
  if (!stdin.hasTerminal) {
    stdinContent = await utf8.decodeStream(stdin);
  }

  final scope = argResults['scope'] as String;
  final workspaceContext =
      _readWorkspaceContext(includeWorkspace: scope == 'workspace');
  final modelName = argResults.wasParsed('model')
      ? argResults['model'] as String
      : (aiConfig?.model ?? argResults['model'] as String);
  final model = GenerativeModel(model: modelName, apiKey: apiKey);

  // Nenhuma pergunta na linha de comando nem em um pipe, mas rodando num
  // terminal de verdade: entra em modo de conversa em vez de mostrar uso.
  if (argsPrompt.isEmpty && stdinContent.isEmpty) {
    if (stdin.hasTerminal) {
      await _runInteractiveChat(
        model: model,
        modelName: modelName,
        workspaceContext: workspaceContext,
      );
      return;
    }
    print('Uso:');
    print('  shepherd ai "seu prompt"');
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

  try {
    final responseStream = model.generateContentStream([
      Content.text(finalPrompt),
    ]);

    await for (final chunk in responseStream) {
      stdout.write(chunk.text);
    }
    stdout.writeln();
  } catch (e) {
    stderr.writeln('\nErro ao comunicar com o Gemini: $e');
    exitCode = 1;
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
  required GenerativeModel model,
  required String modelName,
  required String workspaceContext,
}) async {
  final chat = model.startChat();
  var firstMessage = true;

  print('\n💬 Shepherd AI — modo interativo ($modelName)');
  print('Digite sua pergunta. "sair" (ou Ctrl+D) para encerrar.\n');

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

    try {
      final responseStream = chat.sendMessageStream(Content.text(message));
      await for (final chunk in responseStream) {
        stdout.write(chunk.text);
      }
      stdout.writeln('\n');
    } catch (e) {
      stderr.writeln('\nErro ao comunicar com o Gemini: $e\n');
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
