import 'dart:async';
import 'dart:io';

import '../i18n/i18n.dart';
import '../tools/domain/services/ai_config_service.dart';
import '../tools/presentation/commands/model_switch/model_options.dart';
import '../tools/presentation/commands/model_switch/model_switch_command.dart';
import '../utils/ansi_colors.dart';
import 'diff_view.dart';
import 'engine_session.dart';
import 'rpc_client.dart';
import 'terminal_render.dart';

/// The conversation in the terminal: a thin client. Everything that matters
/// (the model, the retrieval, the files) is the engine's; this reads what the
/// user types, shows what the engine says and asks before a file is written.
class TerminalChat {
  final EngineSession session;
  final TurnRenderer _renderer = TurnRenderer();
  late final StreamSubscription<RpcNotification> _events;

  TerminalChat(this.session) {
    _events = session.client.notifications.listen(_renderer.handle);
  }

  Future<void> close() async {
    await _events.cancel();
    await session.close();
  }

  void printHeader() {
    final where = session.projects.isEmpty
        ? t('chat.whole_workspace')
        : session.projects.join(', ');
    print(
        '\n${AnsiColors.bold}🤖 Shepherd AI${AnsiColors.reset} — ${AnsiColors.brightCyan}${session.model}${AnsiColors.reset} (${providerDisplayName(session.provider)}) | ${t('chat.mode_where', {
          'mode': session.mode,
          'where': where
        })}');
    if (session.offline) {
      print(
          '${AnsiColors.yellow}${t('chat.offline_notice')}${AnsiColors.reset}');
    }
    print('');
  }

  /// The line above the prompt that reminds the user of the /commands; the
  /// short form when the terminal is too narrow for the full one.
  static String promptHint([int? columns]) {
    var cols = columns ?? 80;
    if (columns == null) {
      try {
        if (stdout.hasTerminal) cols = stdout.terminalColumns;
      } catch (_) {}
    }
    final full = t('chat.hint_full');
    final text = full.length + 2 <= cols ? full : t('chat.hint_short');
    final colored = text.replaceAllMapped(
        RegExp(r'/[a-z]+'),
        (m) => '${AnsiColors.brightCyan}${AnsiColors.bold}${m[0]}'
            '${AnsiColors.reset}${AnsiColors.gray}');
    return '${AnsiColors.gray}${'─' * (cols.clamp(20, 100) - 1)}\n $colored${AnsiColors.reset}';
  }

  /// The prompt loop, until the user leaves or the input ends.
  Future<void> interactive() async {
    printHeader();
    while (true) {
      await Future<void>.delayed(
          Duration.zero); // let pending engine messages print first
      print(promptHint());
      stdout.write('${AnsiColors.bold}[${session.mode}]${AnsiColors.reset} > ');
      final line = stdin.readLineSync()?.trim();
      if (line == null) break;
      if (line.isEmpty) continue;
      if (const {'exit', 'quit', ':q', 'sair', 'salir'}
          .contains(line.toLowerCase())) {
        break;
      }
      if (line.startsWith('/')) {
        final ask = await _command(line);
        if (ask == null) continue;
        await this.ask(ask);
      } else {
        await ask(line);
      }
    }
    print(t('chat.bye'));
  }

  /// Sends one question and shows the answer. Returns false when it failed.
  Future<bool> ask(String text, {bool canPrompt = true}) async {
    int? turn;
    final sigint = ProcessSignal.sigint.watch().listen((_) {
      if (turn != null) session.client.cancel(turn!);
    });
    final began = DateTime.now();
    try {
      final r =
          await session.client.request('session/send', {'text': text}, (id) {
        turn = id;
        _renderer.startTurn(id);
      });
      _renderer.endTurn();
      if (r['stopReason'] == 'cancelled') {
        print('${AnsiColors.gray}${t('chat.interrupted')}${AnsiColors.reset}');
      }
      _footer(r, DateTime.now().difference(began));
      await _confirmProposals(canPrompt);
      return true;
    } on RpcException catch (e) {
      _renderer.endTurn();
      stderr.writeln('\n❌ ${describeRpcError(e)}\n');
      return false;
    } finally {
      await sigint.cancel();
    }
  }

  void _footer(Map<String, dynamic> result, Duration took) {
    final u = (result['usage'] as Map?)?.cast<String, dynamic>() ?? const {};
    final local = u['isLocal'] == true;
    print('${AnsiColors.gray}🧠 ${t('chat.footer', {
          'model': session.model,
          'provider': providerDisplayName(session.provider),
          'mode': session.mode,
          'ms': took.inMilliseconds,
          'prompt': u['promptTokens'],
          'completion': u['completionTokens'],
          'kind': t(local ? 'chat.kind_local' : 'chat.kind_cloud'),
        })}${AnsiColors.reset}');
  }

  /// In fast mode the engine waits for a yes before it writes a file.
  Future<void> _confirmProposals(bool canPrompt) async {
    final pending = List<Proposal>.of(_renderer.proposals);
    _renderer.proposals.clear();
    if (pending.isEmpty) return;
    if (!canPrompt || !stdin.hasTerminal) {
      print('${AnsiColors.yellow}${t('chat.unsaved', {
            'n': pending.length
          })}${AnsiColors.reset}');
      return;
    }
    for (final p in pending) {
      print(
          '\n${AnsiColors.bold}${t('chat.proposed_change')}${AnsiColors.reset}');
      final f = File(p.path);
      print(renderDiff(
          path: p.path,
          original: p.isNew || !f.existsSync() ? null : f.readAsStringSync(),
          content: p.content));
      stdout.write(t('chat.apply_prompt',
          {'path': '${AnsiColors.brightCyan}${p.path}${AnsiColors.reset}'}));
      final a = stdin.readLineSync()?.trim().toLowerCase();
      final yes = a == null ||
          a.isEmpty ||
          const {'y', 'yes', 's', 'sim', 'si', 's\u00ed'}.contains(a);
      try {
        final r = await session.client
            .request('session/confirm', {'proposalId': p.id, 'approved': yes});
        print(yes
            ? (r['applied'] == true
                ? t('chat.applied', {
                    'path':
                        '${AnsiColors.brightGreen}${p.path}${AnsiColors.reset}'
                  })
                : t('chat.write_failed', {'path': p.path}))
            : t('chat.skipped', {'path': p.path}));
      } on RpcException catch (e) {
        stderr.writeln('❌ ${describeRpcError(e)}');
      }
    }
  }

  /// Handles a `/command`. Returns text to ask afterwards, or null.
  Future<String?> _command(String line) async {
    final parts = line.split(RegExp(r'\s+'));
    final cmd = parts.first.toLowerCase();
    final rest = parts.skip(1).join(' ').trim();
    try {
      switch (cmd) {
        case '/plan' || '/plano' || '/auto' || '/fast':
          await session
              .setMode(cmd.replaceAll('/', '').replaceAll('plano', 'plan'));
          print(t('chat.mode_set', {'mode': session.mode}));
          return rest.isEmpty ? null : rest;
        case '/mode' || '/modo':
          if (const {'fast', 'plan', 'auto'}.contains(rest)) {
            await session.setMode(rest);
            print(t('chat.mode_set', {'mode': session.mode}));
          } else {
            print(t('chat.mode_current', {'mode': session.mode}));
          }
        case '/model' || '/modelo' || '/trocar-modelo':
          await _switchModel(rest);
        case '/projects' || '/projetos' || '/proyectos':
          await session.setProjects(rest.isEmpty
              ? []
              : rest
                  .split(RegExp(r'[,\s]+'))
                  .where((s) => s.isNotEmpty)
                  .toList());
          print(t('chat.scope_set', {
            'scope': session.projects.isEmpty
                ? t('chat.whole_workspace')
                : session.projects.join(', ')
          }));
        case '/rag':
          print(t('chat.rag_note'));
        case '/help' || '/ajuda' || '/ayuda' || '/?':
          _help();
        default:
          print(t('chat.unknown_command'));
      }
    } on RpcException catch (e) {
      stderr.writeln('❌ ${describeRpcError(e)}');
    }
    return null;
  }

  Future<void> _switchModel(String arg) async {
    final config = AiConfigService().load();
    final choice = await chooseModel(
        aiConfig: config,
        arg: arg,
        activeProvider: session.provider,
        activeModel: session.model);
    if (choice.cancelled) {
      print(t('chat.switch_cancelled', {'model': session.model}));
      return;
    }
    final selected = choice.selected;
    if (selected == null) {
      print(t('chat.model_unknown'));
      return;
    }
    saveModelChoice(
        config, selected); // the engine reads the file again on setModel
    await session.setModel(selected.provider, selected.model);
    print('${AnsiColors.brightGreen}${t('chat.model_changed', {
          'model': session.model,
          'provider': providerDisplayName(session.provider)
        })}${AnsiColors.reset}');
  }

  void _help() => print(t('chat.help'));
}
