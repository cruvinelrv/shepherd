import 'dart:io';

import 'package:shepherd/src/i18n/i18n.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';
import 'package:shepherd/src/version.dart';
import '../../data/models/shell_session_model.dart';
import '../../domain/services/ai_model_catalog_service.dart';

/// What the interactive shell prints besides command output: the welcome
/// banner, the status panel and the help list.
class ShellViews {
  /// The workspace's name, the project's when only that is known, or a hint.
  static String _workspace(ShellSessionModel session) =>
      session.workspaceName ??
      (session.projectName.isNotEmpty
          ? session.projectName
          : t('shell.no_workspace'));

  static String _model(ShellSessionModel session, String tier) => tier == 'deep'
      ? 'gemini-2.5-pro'
      : (session.aiModel ?? AiModelCatalogService.defaultGeminiModel);

  static void banner(
    ShellSessionModel session, {
    required String mode,
    required String tier,
    required String profile,
    bool compact = false,
  }) {
    final model = _model(session, tier);
    final workspace = _workspace(session);
    final c = AnsiColors.brightCyan, x = AnsiColors.reset;

    if (compact) {
      print('${AnsiColors.brightBlue}🐑 Shepherd Shell v$shepherdVersion '
          '[$workspace] (${t('shell.engine_label')}: $model | RAG: Local)$x\n');
      return;
    }

    final who =
        session.userName ?? session.environment ?? t('shell.banner_active');
    final auth = session.isAuthenticated
        ? '🔑 Auth:      ${t('shell.banner_connected', {'who': who})}'
        : '🌐 Auth:      ${t('shell.banner_offline')}';
    const w = 68;
    print('\n${AnsiColors.brightBlue}╭${'─' * w}╮$x');
    print(_line(
        '  🐑 ${AnsiColors.bold}Shepherd Interactive Shell (REPL)$x v$shepherdVersion',
        w));
    print(_line('  by Marmelotech (https://marmelo.tech)', w));
    print('${AnsiColors.brightBlue}├${'─' * w}┤$x');
    print(_line('  🏢 Workspace: $workspace', w));
    print(_line('  $auth', w));
    print(_line('  🤖 AI:        $model [Profile: $profile | Mode: $mode]', w));
    print('${AnsiColors.brightBlue}╰${'─' * w}╯$x');
    print(t('shell.banner_offline_tools'));
    print(t('shell.banner_tip', {
      'file': '$c${t('shell.banner_file_word')}$x',
      'help': '$c${t('shell.banner_help_word')}$x',
    }));
  }

  static void status(
    ShellSessionModel session, {
    required String tier,
    required String mode,
  }) {
    final model = _model(session, tier);
    final provider = session.aiProvider ?? 'Shepherd Platform (Marmelotech)';
    final workspace = _workspace(session);
    final b = AnsiColors.bold, x = AnsiColors.reset;
    final user = session.userName ?? t('shell.status_no_user');
    final email = session.userEmail != null ? '(${session.userEmail})' : '';
    final auth = session.isAuthenticated
        ? '${AnsiColors.brightGreen}${t('shell.status_authed', {
                'env': session.environment ?? 'prod'
              })}$x'
        : '${AnsiColors.brightYellow}${t('shell.status_not_authed')}$x';
    print('\n$b${AnsiColors.brightCyan}${t('shell.status_title')}$x');
    print('  ${b}Workspace:$x      $workspace (${Directory.current.path})');
    print('  $b${t('shell.status_user')}$x  $user $email');
    print('  $b${t('shell.status_auth')}$x   $auth');
    print(
        '  $b${t('shell.status_engine')}$x      ${AnsiColors.brightCyan}$model$x ($provider)');
    print(
        '  $b${t('shell.status_level')}$x       Tier: ${AnsiColors.brightYellow}$tier$x | ${t('shell.status_mode')} ${AnsiColors.brightCyan}$mode$x\n');
  }

  static void help() {
    final g = AnsiColors.brightGreen, x = AnsiColors.reset;
    String row(String cmd, String key) => '  $g${cmd.padRight(22)}$x ${t(key)}';
    print([
      '${AnsiColors.bold}${AnsiColors.brightCyan}${t('shell.help_title')}$x',
      '',
      row(t('shell.help_question'), 'shell.h_question'),
      row('ai <prompt>', 'shell.h_ai'),
      row('@path/file', 'shell.h_file'),
      row('advanced', 'shell.h_advanced'),
      row('medium', 'shell.h_medium'),
      row('local', 'shell.h_local'),
      row('ai --plan <goal>', 'shell.h_plan'),
      row('ai --auto <goal>', 'shell.h_auto'),
      row('model / engine', 'shell.h_model'),
      row('mcp [list|status|call]', 'shell.h_mcp'),
      row('mode <fast|plan|auto>', 'shell.h_mode'),
      row('tier <fast|deep>', 'shell.h_tier'),
      row('cd <folder | project>', 'shell.h_cd'),
      row('pwd', 'shell.h_pwd'),
      row('workspace / ws', 'shell.h_ws'),
      row('clean [target]', 'shell.h_clean'),
      row('login', 'shell.h_login'),
      row('changelog', 'shell.h_changelog'),
      row('flow', 'shell.h_flow'),
      row('deploy', 'shell.h_deploy'),
      row('test', 'shell.h_test'),
      row('status / whoami', 'shell.h_status'),
      row('lang [en|pt|es]', 'shell.h_lang'),
      row('clear / cls', 'shell.h_clear'),
      row('menu', 'shell.h_menu'),
      row('help / ajuda / ayuda', 'shell.h_help'),
      row('exit / quit', 'shell.h_exit'),
      '',
    ].join('\n'));
  }

  static String _line(String content, int boxWidth) {
    final w = _visualWidth(content);
    final pad = (boxWidth - w).clamp(0, 200);
    return '${AnsiColors.brightBlue}│${AnsiColors.reset}$content${' ' * pad}${AnsiColors.brightBlue}│${AnsiColors.reset}';
  }

  static int _visualWidth(String str) {
    final clean = str.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
    int width = 0;
    for (final rune in clean.runes) {
      if (rune >= 0x1F300 ||
          (rune >= 0x1100 && rune <= 0x11FF) ||
          (rune >= 0x2E80 && rune <= 0x9FFF) ||
          (rune >= 0xAC00 && rune <= 0xD7AF) ||
          (rune >= 0xF900 && rune <= 0xFAFF) ||
          (rune >= 0xFE10 && rune <= 0xFE19) ||
          (rune >= 0xFE30 && rune <= 0xFE6F) ||
          (rune >= 0xFF00 && rune <= 0xFF60) ||
          (rune >= 0xFFE0 && rune <= 0xFFE6)) {
        width += 2;
      } else {
        width += 1;
      }
    }
    return width;
  }
}
