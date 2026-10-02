import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../data/models/ai_config_model.dart';
import '../../domain/services/ai_jsonl_protocol.dart';
import '../../domain/services/ai_session_runner.dart';
import '../../domain/services/ai_settings_resolver.dart';

/// `shepherd ai --jsonl`: a long-lived conversation driven over stdin/stdout.
/// Requests (one JSON per line): user_message, confirm, cancel, set_model,
/// set_mode, shutdown. Events: see [AiEvent]. The working directory is the
/// workspace root. Human-readable output must never reach stdout, so `print`
/// is redirected to stderr for the whole session.
Future<void> runAiJsonl({
  required AiResolvedSettings settings,
  required String mode,
  required String tier,
  required List<String> projects,
  AiConfigModel? aiConfig,
  Stream<List<int>>? input,
  void Function(String line)? output,
  AiGenerate? generate,
}) {
  final void Function(String) emit = output ?? (line) => stdout.writeln(line);
  return runZoned(
    () => _session(
      settings: settings,
      mode: mode,
      tier: tier,
      projects: projects,
      aiConfig: aiConfig,
      input: input ?? stdin,
      emit: emit,
      generate: generate,
    ),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => stderr.writeln(line),
    ),
  );
}

Future<void> _session({
  required AiResolvedSettings settings,
  required String mode,
  required String tier,
  required List<String> projects,
  AiConfigModel? aiConfig,
  required Stream<List<int>> input,
  required void Function(String) emit,
  AiGenerate? generate,
}) async {
  void send(AiEvent e) => emit(e.encode());

  if (!settings.hasDirectAccess) {
    send(AiEvent.error('not_configured',
        'Provedor "${settings.provider}" sem chave. Configure com `shepherd ai config`.'));
    exitCode = 1;
    return;
  }

  final runner = AiSessionRunner(
    settings: settings,
    workspaceRoot: Directory.current.path,
    projects: projects,
    mode: mode,
    tier: tier,
    generate: generate,
  );
  send(AiEvent.ready(
    provider: settings.provider,
    model: settings.model,
    mode: mode,
    projects: projects,
  ));

  StreamSubscription<AiEvent>? turn;
  final lines = input.transform(utf8.decoder).transform(const LineSplitter());

  await for (final line in lines) {
    final req = AiRequest.tryParse(line);
    if (req == null) continue;
    switch (req.type) {
      case 'user_message':
        final text = req.str('text')?.trim() ?? '';
        if (text.isEmpty) {
          send(AiEvent.error('bad_request', 'user_message sem texto'));
        } else if (turn != null) {
          send(AiEvent.error('busy', 'Aguarde a resposta atual terminar ou envie cancel'));
        } else {
          final current = runner.ask(text).listen(send);
          turn = current;
          current.onDone(() => turn = null);
        }
      case 'confirm':
        final id = req.str('id');
        send(id == null
            ? AiEvent.error('bad_request', 'confirm sem id')
            : runner.confirm(id, approved: req.flag('approved') ?? false));
      case 'cancel':
        runner.cancel();
      case 'set_mode':
        final m = req.str('mode');
        if (m == 'fast' || m == 'plan' || m == 'auto') runner.mode = m!;
      case 'set_model':
        runner.settings = resolveAiSettings(
          provider: req.str('provider'),
          model: req.str('model'),
          targetProfile: req.str('profile'),
          aiConfig: aiConfig,
          isLocalProvider: isLocalAiProvider,
        );
        send(AiEvent('model_changed',
            {'provider': runner.settings.provider, 'model': runner.settings.model}));
      case 'shutdown':
        runner.cancel();
        await turn?.cancel();
        return;
    }
  }
  // stdin closed: let an in-flight answer finish before exiting.
  final pending = turn;
  if (pending != null) {
    final done = Completer<void>();
    pending.onDone(done.complete);
    await done.future;
  }
}
