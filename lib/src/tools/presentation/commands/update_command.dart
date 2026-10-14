import 'dart:io';

import '../../../utils/ansi_colors.dart';
import '../../../version.dart';
import '../../domain/services/install_method_detector.dart';
import '../../domain/services/latest_version_service.dart';
import '../../../i18n/i18n.dart';

/// `shepherd update [--check] [--yes]`: says whether a newer version exists and
/// how to get it for the way this CLI was installed. Runs the update itself
/// only for Homebrew and pub.dev installs, after confirmation.
///
/// Returns the process exit code (0 ok, 1 could not check or the update failed).
Future<int> runUpdateCommand(
  List<String> args, {
  InstallMethod? method,
  LatestVersionService? latest,
  String? currentVersion,
  bool? windows,
  void Function(String line)? out,
  bool Function()? confirm,
  Future<int> Function(String command)? run,
}) async {
  final say = out ?? stdout.writeln;
  final checkOnly = args.contains('--check');
  final assumeYes = args.contains('--yes') || args.contains('-y');
  final isWindows = windows ?? Platform.isWindows;
  final current = currentVersion ?? shepherdVersion;
  final install = method ??
      InstallMethodDetector.detect(
        executable: Platform.resolvedExecutable,
        script: Platform.script.toFilePath(),
      );

  say(t('update.header',
      {'version': current, 'method': InstallMethodDetector.label(install)}));

  final newest = await (latest ?? LatestVersionService()).latestFor(install);
  if (newest == null) {
    say('${AnsiColors.yellow}${t('update.no_check')}${AnsiColors.reset}');
    return 1;
  }
  if (LatestVersionService.compareVersions(newest, current) <= 0) {
    say('${AnsiColors.green}${t('update.up_to_date', {
          'version': current
        })}${AnsiColors.reset}');
    return 0;
  }

  say(t('update.available', {'current': current, 'newest': newest}));
  say(t('update.news',
      {'url': '${LatestVersionService.releaseUrl}/tag/v$newest'}));

  switch (install) {
    case InstallMethod.studioBundled:
      say(t('update.studio'));
      return 0;
    case InstallMethod.source:
      say(t('update.source'));
      return 0;
    case InstallMethod.unknown:
      say(t('update.unknown'));
      say('  Homebrew:  ${InstallMethodDetector.brewCommand}');
      say('  pub.dev:   ${InstallMethodDetector.pubCommand}');
      say('  script:    ${InstallMethodDetector.updateCommand(InstallMethod.installScript, windows: isWindows)}');
      return 0;
    case InstallMethod.installScript:
      // A piped installer is shown, never run on the user's behalf.
      say(t('update.to_update'));
      say('  ${InstallMethodDetector.updateCommand(install, windows: isWindows)}');
      return 0;
    case InstallMethod.homebrew:
    case InstallMethod.pubGlobal:
      final command = InstallMethodDetector.updateCommand(install)!;
      say(t('update.to_update'));
      say('  $command');
      if (install == InstallMethod.homebrew) {
        say('${AnsiColors.gray}${t('update.brew_lag', {
              'newest': newest
            })}${AnsiColors.reset}');
      }
      if (checkOnly) return 0;

      final go = assumeYes || (confirm ?? _askYesNo)();
      if (!go) return 0;
      say(t('update.running'));
      final code = await (run ?? _runInShell)(command);
      if (code == 0) {
        say('${AnsiColors.green}${t('update.done', {
              'newest': newest
            })}${AnsiColors.reset}');
      } else {
        say('${AnsiColors.red}${t('update.failed', {
              'code': code,
              'command': command
            })}${AnsiColors.reset}');
      }
      return code == 0 ? 0 : 1;
  }
}

bool _askYesNo() {
  stdout.write(t('update.ask'));
  final a = stdin.readLineSync()?.trim().toLowerCase();
  return const {'s', 'sim', 'si', 's\u00ed', 'y', 'yes'}.contains(a);
}

/// The commands passed here are fixed constants, never user input.
Future<int> _runInShell(String command) async {
  final proc = Platform.isWindows
      ? await Process.start('cmd', ['/c', command],
          mode: ProcessStartMode.inheritStdio)
      : await Process.start('bash', ['-lc', command],
          mode: ProcessStartMode.inheritStdio);
  return proc.exitCode;
}
