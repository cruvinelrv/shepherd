import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import '../i18n/i18n.dart';
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
    ..addMultiOption('projects', splitCommas: true, help: t('help.projects'))
    ..addOption('model', abbr: 'm', help: t('help.model'))
    ..addOption('provider', abbr: 'p', help: t('help.provider'))
    ..addOption('mode',
        allowed: ['fast', 'plan', 'auto'],
        defaultsTo: 'fast',
        help: t('help.mode'))
    ..addFlag('help', abbr: 'h', negatable: false, hide: true)
    ..addFlag('plan', negatable: false, help: t('help.plan'))
    ..addFlag('auto', negatable: false, help: t('help.auto'))
    ..addFlag('rag', help: t('help.rag'))
    ..addMultiOption('file', abbr: 'f', help: t('help.file'))
    ..addOption('profile', help: t('help.profile'))
    ..addFlag('advanced', negatable: false, hide: true)
    ..addFlag('avancado', negatable: false, hide: true)
    ..addFlag('avanzado', negatable: false, hide: true)
    ..addFlag('medium', negatable: false, hide: true)
    ..addFlag('medio', negatable: false, hide: true)
    ..addFlag('deep', negatable: false, hide: true)
    ..addFlag('local', negatable: false, help: t('help.local'))
    ..addFlag('engine-path', negatable: false, help: t('help.engine_path'))
    ..addFlag('update-engine', negatable: false, help: t('help.update_engine'));
  parser.addCommand('config').addFlag('sync',
      abbr: 's', negatable: false, help: t('help.config_sync'));
  for (final name in ['model', 'modelo', 'change-model']) {
    parser.addCommand(name);
  }
  return parser;
}

/// `shepherd ai`: the CLI's own part is the login, the engine's installation
/// and the terminal. The AI itself runs in the engine, a separate program.
Future<void> runAiLauncher(List<String> arguments) async {
  final ArgResults args;
  try {
    args = createAiParser().parse(arguments);
  } catch (e) {
    print(t('launcher.bad_args', {'e': e, 'usage': t('launcher.usage')}));
    exitCode = 64;
    return;
  }

  if (args['help'] == true && args.command == null) {
    print(t('launcher.usage'));
    print('');
    print(createAiParser().usage);
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
    stderr.writeln(t('launcher.login_required'));
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
      stderr.writeln(t('launcher.file_not_found', {'path': path}));
      continue;
    }
    parts.add(
        '--- File: $path ---\n${f.readAsStringSync()}'); // goes to the model, not to the user
  }
  final typed = a.rest.join(' ').trim();
  final piped = stdin.hasTerminal
      ? ''
      : (await stdin.transform(utf8.decoder).join()).trim();
  if (typed.isEmpty && piped.isEmpty && parts.isEmpty) return null;
  return [...parts, if (piped.isNotEmpty) piped, if (typed.isNotEmpty) typed]
      .join('\n\n');
}
