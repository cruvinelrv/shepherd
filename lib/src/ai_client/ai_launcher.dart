import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import '../tools/domain/services/ai_config_service.dart';
import '../tools/presentation/commands/ai_config_command.dart';
import '../tools/presentation/commands/model_switch/model_switch_command.dart';
import 'engine_installer.dart';
import 'engine_session.dart';
import 'rpc_client.dart';
import 'session_reader.dart';
import 'terminal_chat.dart';
import 'terminal_render.dart';
import 'usage_notice.dart';

ArgParser createAiParser() {
  final parser = ArgParser()
    ..addMultiOption('projects',
        splitCommas: true,
        help:
            'Limita o contexto (e os arquivos que a IA pode alterar) a estes projetos, pastas na raiz do workspace. Vazio = workspace inteiro.')
    ..addOption('model',
        abbr: 'm',
        help: 'Modelo de IA (ex: gemini-3.8-flash, gpt-4o, llama3.1).')
    ..addOption('provider',
        abbr: 'p', help: 'Provedor de IA: gemini, openai, anthropic ou ollama.')
    ..addOption('mode',
        allowed: ['fast', 'plan', 'auto'],
        defaultsTo: 'fast',
        help:
            'fast (pergunta antes de gravar), plan (só planeja) ou auto (grava direto).')
    ..addFlag('plan', negatable: false, help: 'Atalho para --mode plan.')
    ..addFlag('auto', negatable: false, help: 'Atalho para --mode auto.')
    ..addFlag('rag',
        help: 'Liga ou desliga o contexto do workspace (ligado por padrão).')
    ..addMultiOption('file',
        abbr: 'f', help: 'Anexa o conteúdo de arquivos locais à pergunta.')
    ..addOption('profile', help: 'Perfil de modelo: advanced, medium ou local.')
    ..addFlag('advanced', negatable: false, hide: true)
    ..addFlag('avancado', negatable: false, hide: true)
    ..addFlag('avanzado', negatable: false, hide: true)
    ..addFlag('medium', negatable: false, hide: true)
    ..addFlag('medio', negatable: false, hide: true)
    ..addFlag('deep', negatable: false, hide: true)
    ..addFlag('local', negatable: false, help: 'Usa o perfil de modelo local.')
    ..addFlag('engine-path',
        negatable: false,
        help: 'Mostra onde está o motor de IA (instalando-o se faltar).')
    ..addFlag('update-engine',
        negatable: false,
        help: 'Procura agora uma versão nova do motor de IA.');
  parser.addCommand('config').addFlag('sync',
      abbr: 's',
      negatable: false,
      help: 'Sincroniza o catálogo de modelos online.');
  for (final name in ['model', 'modelo', 'change-model']) {
    parser.addCommand(name);
  }
  return parser;
}

const _usage =
    '''Uso: shepherd ai ["sua pergunta"] [-m modelo] [-p provedor] [--plan|--auto] [--projects a,b] [-f arquivo]
     shepherd ai config [--sync]
     shepherd ai model [nome_do_modelo]
     shepherd ai --engine-path | --update-engine''';

/// `shepherd ai`: the CLI's own part is the login, the engine's installation
/// and the terminal. The AI itself runs in the engine, a separate program.
Future<void> runAiLauncher(List<String> arguments) async {
  final ArgResults args;
  try {
    args = createAiParser().parse(arguments);
  } catch (e) {
    print('❌ Erro: $e\n$_usage');
    exitCode = 64;
    return;
  }

  switch (args.command?.name) {
    case 'config':
      await runAiConfigCommand(args.command!.arguments);
      return;
    case 'model' || 'modelo' || 'change-model':
      await handleModelSwitchCommand(args.command!.arguments);
      return;
  }

  final installer = EngineInstaller(onProgress: print);
  final File engine;
  try {
    engine = await installer.ensure(force: args['update-engine'] == true);
  } on EngineInstallException catch (e) {
    stderr.writeln('❌ $e');
    exitCode = 1;
    return;
  }
  if (args['engine-path'] == true || args['update-engine'] == true) {
    print(engine.path);
    return;
  }

  final login = LoginSession.read();
  if (login == null) {
    stderr.writeln('❌ Faça login para usar o Shepherd AI: `shepherd login`.');
    exitCode = 1;
    return;
  }

  // The usage report is on by default, so the user is told once (on stderr: a
  // redirected answer stays clean).
  final notice = UsageNotice.takeIfDue();
  if (notice != null) stderr.writeln('\n$notice\n');

  var provider = args['provider'] as String?;
  var model = args['model'] as String?;
  final profile = _profile(args);
  if (profile != null && provider == null && model == null) {
    final slot = AiConfigService().load()?.resolveProfileSlot(profile);
    provider = slot?.provider;
    model = slot?.model;
  }
  final mode = args['plan'] == true
      ? 'plan'
      : (args['auto'] == true ? 'auto' : args['mode'] as String);

  final EngineSession session;
  try {
    session = await EngineSession.start(
      exe: engine,
      login: login,
      provider: provider,
      model: model,
      mode: mode,
      projects: args['projects'] as List<String>,
      rag: args.wasParsed('rag') ? args['rag'] as bool : null,
    );
  } on RpcException catch (e) {
    stderr.writeln('❌ ${describeRpcError(e)}');
    exitCode = 1;
    return;
  }

  final chat = TerminalChat(session);
  try {
    final question = await _question(args);
    if (question == null) {
      await chat.interactive();
    } else if (!await chat.ask(question, canPrompt: stdin.hasTerminal)) {
      exitCode = 1;
    }
  } finally {
    await chat.close();
  }
}

String? _profile(ArgResults a) {
  if (a['advanced'] == true ||
      a['avancado'] == true ||
      a['avanzado'] == true ||
      a['deep'] == true) return 'advanced';
  if (a['local'] == true) return 'local';
  if (a['medium'] == true || a['medio'] == true) return 'medium';
  return a['profile'] as String?;
}

/// The question given as arguments, files and/or piped input; null means
/// "open the conversation".
Future<String?> _question(ArgResults a) async {
  final parts = <String>[];
  for (final path in a['file'] as List<String>) {
    final f = File(path);
    if (!f.existsSync()) {
      stderr.writeln('⚠️  Arquivo não encontrado: $path');
      continue;
    }
    parts.add('--- Arquivo: $path ---\n${f.readAsStringSync()}');
  }
  final typed = a.rest.join(' ').trim();
  final piped = stdin.hasTerminal
      ? ''
      : (await stdin.transform(utf8.decoder).join()).trim();
  if (typed.isEmpty && piped.isEmpty && parts.isEmpty) return null;
  return [...parts, if (piped.isNotEmpty) piped, if (typed.isNotEmpty) typed]
      .join('\n\n');
}
