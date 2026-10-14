import 'dart:io';

import '../../../ai_client/session_reader.dart';
import '../../../i18n/i18n.dart';
import '../../../utils/ansi_colors.dart';
import '../../domain/services/union_workspace_service.dart';

/// What the shell offers in a folder that has no `.shepherd/workspace.yaml`:
/// sign in and take the company's workspace from the Union, start a new project
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

  /// Shows the menu until the user settles. Returns true when the shell should
  /// go on (a workspace was set up or a new project was started), false when the
  /// user left or the input ended: nothing in the CLI works without `.shepherd/`.
  Future<bool> run() async {
    say('\n${AnsiColors.bold}${t('gate.title')}${AnsiColors.reset}');
    say(t('gate.explain'));
    while (true) {
      say('  [1] ${t('gate.opt_login')}');
      say('  [2] ${t('gate.opt_init')}');
      say('  [3] ${t('gate.opt_skip')}');
      final choice = readLine()?.trim();
      switch (choice) {
        case null:
          return false;
        case '1':
          if (await _fromUnion()) return true;
        case '2':
          await init();
          return true;
        case '3' || 'exit' || 'quit' || 'q':
          return false;
        default:
          say(t('gate.invalid'));
      }
    }
  }

  /// Signs in and writes the company's workspace here. False sends the user
  /// back to the menu.
  Future<bool> _fromUnion() async {
    await login();
    final session = readLogin(dir);
    if (session == null) {
      say(t('gate.no_login'));
      return false;
    }
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
