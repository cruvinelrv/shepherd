import 'dart:io';

import '../../../utils/ansi_colors.dart';
import '../../../version.dart';
import '../../domain/services/install_method_detector.dart';
import '../../domain/services/latest_version_service.dart';

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

  say('Shepherd CLI $current — instalação: ${InstallMethodDetector.label(install)}');

  final newest = await (latest ?? LatestVersionService()).latestFor(install);
  if (newest == null) {
    say('${AnsiColors.yellow}Não consegui consultar a versão mais recente (sem internet?). '
        'Tente de novo mais tarde.${AnsiColors.reset}');
    return 1;
  }
  if (LatestVersionService.compareVersions(newest, current) <= 0) {
    say('${AnsiColors.green}✅ Você já está na versão mais recente ($current).${AnsiColors.reset}');
    return 0;
  }

  say('📦 Nova versão disponível: $current → $newest');
  say('   Novidades: ${LatestVersionService.releaseUrl}/tag/v$newest');

  switch (install) {
    case InstallMethod.studioBundled:
      say('Este CLI vem dentro do Shepherd Studio: atualize o Studio para receber a nova versão.');
      return 0;
    case InstallMethod.source:
      say('Você está rodando do código-fonte: atualize o repositório (git pull && dart pub get).');
      return 0;
    case InstallMethod.unknown:
      say('Não sei como este CLI foi instalado. Use o comando do seu caso:');
      say('  Homebrew:  ${InstallMethodDetector.brewCommand}');
      say('  pub.dev:   ${InstallMethodDetector.pubCommand}');
      say('  script:    ${InstallMethodDetector.updateCommand(InstallMethod.installScript, windows: isWindows)}');
      return 0;
    case InstallMethod.installScript:
      // A piped installer is shown, never run on the user's behalf.
      say('Para atualizar, rode:');
      say('  ${InstallMethodDetector.updateCommand(install, windows: isWindows)}');
      return 0;
    case InstallMethod.homebrew:
    case InstallMethod.pubGlobal:
      final command = InstallMethodDetector.updateCommand(install)!;
      say('Para atualizar, rode:');
      say('  $command');
      if (install == InstallMethod.homebrew) {
        say('${AnsiColors.gray}Se o Homebrew disser que já está atualizado, a fórmula ainda não '
            'recebeu a $newest: tente mais tarde.${AnsiColors.reset}');
      }
      if (checkOnly) return 0;

      final go = assumeYes || (confirm ?? _askYesNo)();
      if (!go) return 0;
      say('⏳ Atualizando...');
      final code = await (run ?? _runInShell)(command);
      if (code == 0) {
        say('${AnsiColors.green}✅ Pronto. Abra um novo terminal para usar a $newest.${AnsiColors.reset}');
      } else {
        say('${AnsiColors.red}❌ A atualização falhou (código $code). Rode manualmente: $command${AnsiColors.reset}');
      }
      return code == 0 ? 0 : 1;
  }
}

bool _askYesNo() {
  stdout.write('\nAtualizar agora? [s/N]: ');
  final a = stdin.readLineSync()?.trim().toLowerCase();
  return a == 's' || a == 'sim' || a == 'y' || a == 'yes';
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
