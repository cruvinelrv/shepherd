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
import 'command_runner.dart';
import 'terminal_render.dart';

/// The conversation in the terminal: a thin client. Everything that matters
/// (the model, the retrieval, the files) is the engine's; this reads what the
/// user types, shows what the engine says and asks before a file is written.
class TerminalChat {
  final EngineSession session;
  final TurnRenderer _renderer = TurnRenderer();
  final CommandRunner commandRunner;
  late final StreamSubscription<RpcNotification> _events;

  TerminalChat(this.session, {CommandRunner? commandRunner})
      : commandRunner = commandRunner ?? CommandRunner() {
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
  ///
  /// Files and terminal commands the AI proposes are confirmed here; when commands
  /// ran, their results go back to the AI (at most [maxFollowUps] times in a row)
  /// so it can go on or fix what failed.
  Future<bool> ask(String text, {bool canPrompt = true, int depth = 0}) async {
    int? turn;
    final sigint = ProcessSignal.sigint.watch().listen((_) {
      if (turn != null) session.client.cancel(turn!);
    });
    final began = DateTime.now();
    List<CommandResult> results = const [];
    try {
      final r =
          await session.client.request('session/send', {'text': text}, (id) {
        turn = id;
        _renderer.startTurn(id);
      });
      turn = null; // nothing of this turn is left to cancel
      // The engine's last notifications of the turn may still be on their way
      // through the stream when its answer arrives; let them be handled first.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      _renderer.endTurn();
      if (r['stopReason'] == 'cancelled') {
        print('${AnsiColors.gray}${t('chat.interrupted')}${AnsiColors.reset}');
      }
      _footer(r, DateTime.now().difference(began));
      final cmds = List<CommandProposal>.of(_renderer.commands);
      _renderer.commands.clear();
      if (cmds.isNotEmpty && cmds.first.before) {
        results = await _runCommands(cmds, canPrompt);
      }
      await _confirmProposals(canPrompt);
      if (cmds.isNotEmpty && !cmds.first.before) {
        results = await _runCommands(cmds, canPrompt);
      }
    } on RpcException catch (e) {
      _renderer.endTurn();
      stderr.writeln('\n❌ ${describeRpcError(e)}\n');
      return false;
    } finally {
      await sigint.cancel();
    }
    if (results.isNotEmpty && depth < maxFollowUps) {
      print('${AnsiColors.gray}${t('cmd.sending_results')}${AnsiColors.reset}');
      return ask(_resultsText(results), canPrompt: canPrompt, depth: depth + 1);
    }
    return true;
  }

  /// The most times in a row the results of commands go back to the AI.
  static const maxFollowUps = 3;

  /// Shows each proposed command and runs it when the user says yes. In `auto` a
  /// command that is not risky runs without asking; a risky one is always asked.
  Future<List<CommandResult>> _runCommands(
      List<CommandProposal> cmds, bool canPrompt) async {
    if (!canPrompt || !stdin.hasTerminal) {
      print('${AnsiColors.yellow}${t('cmd.not_run', {
            'n': cmds.length
          })}${AnsiColors.reset}');
      return const [];
    }
    final results = <CommandResult>[];
    for (final c in cmds) {
      final colour = c.risky ? AnsiColors.brightRed : AnsiColors.brightCyan;
      print(
          '\n${AnsiColors.bold}${t('cmd.proposed')}${AnsiColors.reset} ${AnsiColors.gray}${c.cwd}${AnsiColors.reset}');
      print(
          '  $colour\$ ${c.command.replaceAll('\n', '\n    ')}${AnsiColors.reset}');
      if (c.risky) {
        print('${AnsiColors.brightRed}${t('cmd.risky')}${AnsiColors.reset}');
      }
      final auto = session.mode == 'auto' && !c.risky;
      if (auto) {
        print('${AnsiColors.gray}${t('cmd.auto_run')}${AnsiColors.reset}');
      } else {
        stdout.write(t(c.risky ? 'cmd.ask_risky' : 'cmd.ask'));
        final a = stdin.readLineSync()?.trim().toLowerCase() ?? '';
        if (!const {'y', 'yes', 's', 'sim', 'si', 's\u00ed'}.contains(a)) {
          print('${AnsiColors.gray}${t('cmd.skipped')}${AnsiColors.reset}');
          continue;
        }
      }
      if (!Directory(c.cwd).existsSync()) {
        print('${AnsiColors.red}${t('cmd.no_folder', {
              'path': c.cwd
            })}${AnsiColors.reset}');
        continue;
      }
      print('${AnsiColors.gray}${t('cmd.ctrl_c')}${AnsiColors.reset}');
      final r = await commandRunner.run(c.command, c.cwd);
      results.add(r);
      print(r.timedOut
          ? '${AnsiColors.red}${t('cmd.timed_out')}${AnsiColors.reset}'
          : r.interrupted
              ? '${AnsiColors.yellow}${t('cmd.stopped')}${AnsiColors.reset}'
              : r.ok
                  ? '${AnsiColors.brightGreen}${t('cmd.ok')}${AnsiColors.reset}'
                  : '${AnsiColors.red}${t('cmd.failed', {
                          'code': r.exitCode
                        })}${AnsiColors.reset}');
    }
    return results;
  }

  /// What goes back to the model: written for it, so in English.
  static String _resultsText(List<CommandResult> results) {
    final b = StringBuffer('Command results:\n');
    for (final r in results) {
      b
        ..writeln('\$ ${r.command}')
        ..writeln(r.timedOut
            ? 'timed out'
            : r.interrupted
                ? 'stopped by the user (Ctrl+C) after ${r.took.inSeconds}s, which is how a server such as `flutter run` is ended'
                : 'exit code ${r.exitCode}');
      if (r.tail.trim().isNotEmpty)
        b.writeln('output (end):\n${r.tail.trim()}');
      b.writeln();
    }
    b.write('Go on with the plan. If a command failed, fix it.');
    return b.toString();
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
        case '/run' || '/go' || '/exec' || '/executar' || '/ejecutar':
          // Carry the plan out: files with confirmation, commands asked one by one.
          final auto = rest.toLowerCase() == 'auto';
          if (auto || session.mode == 'plan') {
            await session.setMode(auto ? 'auto' : 'fast');
          }
          print(t('cmd.running_plan', {'mode': session.mode}));
          return 'Carry out the plan above now. Write the files, and give the '
              'terminal commands in bash blocks, in the order they must run.';
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
