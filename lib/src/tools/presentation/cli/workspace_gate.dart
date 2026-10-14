import 'dart:io';

import '../../../ai_client/session_reader.dart';
import '../../../i18n/i18n.dart';
import '../../../utils/ansi_colors.dart';
import '../../domain/services/union_workspace_service.dart';

/// What the shell offers in a folder that has no `.shepherd/workspace.yaml`:
/// sign in (first), then take the company's workspace from the Union, start a new project
/// here, or leave. Nothing is created until the user picks.
class WorkspaceGate {
  final Future<void> Function() login;
  final Future<void> Function() init;
  final UnionWorkspaceService union;
  final String? Function() readLine;
  final void Function(String) say;
  final Directory dir;
  final LoginSession? Function(Directory) readLogin;

  WorkspaceGate({
    required this.login,
    required this.init,
    UnionWorkspaceService? union,
    String? Function()? readLine,
    void Function(String)? say,
    Directory? dir,
    LoginSession? Function(Directory)? readLogin,
  })  : union = union ?? UnionWorkspaceService(),
        readLine = readLine ?? (() => stdin.readLineSync()),
        say = say ?? print,
        dir = dir ?? Directory.current,
        readLogin = readLogin ?? ((d) => LoginSession.read(d));

  /// Offers the ways to start; the login comes first on the ways that need an
  /// account (the company's workspace, the AI) and never blocks the dev tools
  /// (`clean`, `changelog`, `flow`, `deploy`), which work without an account or a
  /// workspace. Returns true when the shell should go on, false when the user
  /// left or the input ended.
  Future<bool> run() async {
    say('\n${AnsiColors.bold}${t('gate.title')}${AnsiColors.reset}');
    say(t('gate.explain'));
    while (true) {
      say('  [1] ${t('gate.opt_union')}');
      say('  [2] ${t('gate.opt_init')}');
      say('  [3] ${t('gate.opt_tools')}');
      say('  [4] ${t('gate.opt_exit')}');
      final choice = readLine()?.trim();
      switch (choice) {
        case null:
          return false;
        case '1':
          if (readLogin(dir) == null && !await _signIn()) break;
          if (await _fromUnion()) return true;
        case '2':
          if (readLogin(dir) == null) await _offerSignIn();
          await init();
          return true;
        case '3':
          return true;
        case '4' || 'exit' || 'quit' || 'q':
          return false;
        default:
          say(t('gate.invalid'));
      }
    }
  }

  /// Asks for the login until there is one. False when the user gives up.
  Future<bool> _signIn() async {
    while (true) {
      await login();
      if (readLogin(dir) != null) return true;
      say(t('gate.no_login'));
      say(t('gate.retry'));
      final line = readLine()?.trim().toLowerCase();
      if (line == null || const {'n', 'no', 'nao', 'n\u00e3o'}.contains(line)) {
        return false;
      }
    }
  }

  /// Before a new workspace: sign in now, which the AI needs, or skip it.
  Future<void> _offerSignIn() async {
    say(t('gate.login_first'));
    final line = readLine()?.trim().toLowerCase() ?? 'n';
    if (line.isEmpty || const {'y', 'yes', 's', 'sim', 'si'}.contains(line)) {
      await login();
    }
  }

  /// Reads the company's workspace from the Union and writes it here. False
  /// sends the user back to the menu.
  Future<bool> _fromUnion() async {
    final session = readLogin(dir);
    if (session == null) return false;
    say(t('gate.fetching'));
    UnionWorkspace? ws;
    try {
      ws = await union.fetch(session);
    } on UnionWorkspaceException catch (e) {
      say('${AnsiColors.red}${t('gate.fetch_failed', {
            'error': e.message
          })}${AnsiColors.reset}');
      return false;
    }
    if (ws == null) {
      say(t('gate.none_in_union'));
      return false;
    }
    UnionWorkspaceService.write(ws, dir);
    say('${AnsiColors.brightGreen}${t('gate.done', {
          'name': ws.name,
          'n': ws.projectCount
        })}${AnsiColors.reset}');
    return true;
  }
}
