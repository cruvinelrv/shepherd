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
    );
  parser.addCommand('config');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print('❌ Error: ${e.toString()}');
    print('Usage: shepherd ai "seu prompt" [--model <modelo>]');
    print('       shepherd ai config');
    return;
  }

  if (argResults.command?.name == 'config') {
    await runAiConfigCommand();
    return;
  }

  final sessionToken = _getGlobalToken();
  if (sessionToken == null || sessionToken.isEmpty) {
    stderr.writeln('Erro: você precisa estar autenticado para usar o shepherd ai.');
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

  if (argsPrompt.isEmpty && stdinContent.isEmpty) {
    print('Uso:');
    print('  shepherd ai "seu prompt"');
    print('  cat arquivo.txt | shepherd ai "resuma"');
    return;
  }

  final buffer = StringBuffer();
  final workspaceContext = _readWorkspaceContext();
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
  final modelName = argResults.wasParsed('model')
      ? argResults['model'] as String
      : (aiConfig?.model ?? argResults['model'] as String);

  try {
    final model = GenerativeModel(model: modelName, apiKey: apiKey);

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
/// context instead of a bare prompt.
String _readWorkspaceContext() {
  const paths = [
    '.shepherd/project.yaml',
    '.shepherd/environments.yaml',
    'devops/domains.yaml',
  ];

  final buffer = StringBuffer();

  // workspace.yaml gets a summary, not a raw dump — Studio's format nests
  // projects by category, which reads worse to an LLM than one line each.
  final workspace = WorkspaceManifest.tryLoad();
  if (workspace != null && workspace.projects.isNotEmpty) {
    buffer.writeln('# .shepherd/workspace.yaml');
    buffer.writeln(workspace.toSummary());
    buffer.writeln();
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
