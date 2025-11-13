import 'dart:io';
import '../../domain/services/changelog_service.dart';
import '../../../menu/presentation/cli/direct_commands.dart';
import '../../../menu/presentation/cli/general_menu.dart';
import '../../../utils/cli_parser.dart';
import '../commands/clean_command.dart';
import '../commands/deploy_command.dart';
import '../commands/init_command.dart';
import '../commands/git_recover_command.dart';

/// Main Shepherd CLI runner
Future<void> runShepherd(List<String> arguments) async {
  if (arguments.isEmpty) {
    // No arguments, show main menu
    await showGeneralMenuLoop();
    return;
  }

  final parser = buildShepherdArgParser();

  try {
    final results = parser.parse(arguments);
    final command = results.command?.name;

    switch (command) {
      case 'changelog':
        await _handleChangelogCommand();
        break;
      case 'clean':
        await runCleanCommand(arguments.skip(1).toList());
        break;
      case 'deploy':
        await runDeployCommand(arguments.skip(1).toList());
        break;
      case 'init':
        await runInitCommand(arguments.skip(1).toList());
        break;
      case 'gitrecover':
        await runGitRecoverStepByStep();
        break;
      case 'help':
        DirectCommandsMenu.printShepherdHelp();
        break;
      case 'about':
        DirectCommandsMenu.printShepherdAbout();
        break;
      default:
        if (arguments.isNotEmpty) {
          print('Unknown command: ${arguments.first}');
          print('');
        }
        DirectCommandsMenu.printShepherdHelp();
    }
  } catch (e) {
    print('Error parsing arguments: $e');
    DirectCommandsMenu.printShepherdHelp();
  }
}

/// Handle changelog command
Future<void> _handleChangelogCommand() async {
  try {
    stdout.write(
        'Enter the base branch for the changelog (e.g., main, develop): ');
    final baseBranch = stdin.readLineSync()?.trim();

    if (baseBranch == null || baseBranch.isEmpty) {
      print('Base branch not provided.');
      return;
    }

    final service = ChangelogService();
    final updatedPaths = await service.updateChangelog(baseBranch: baseBranch);

    if (updatedPaths.isNotEmpty) {
      print('CHANGELOG.md successfully updated for:');
      for (final path in updatedPaths) {
        print('  - $path');
      }
    } else {
      print('No changes detected.');
    }
  } catch (e) {
    print('Error updating changelog: $e');
    exit(1);
  }
}

/// Step-by-step interface for gitrecover
Future<void> runGitRecoverStepByStep() async {
  print('\nShepherd GitRecover - Recuperação de Changelog por Data');
  String? baseBranch;
  String? sinceStr;
  String? untilStr;
  DateTime? since;
  DateTime? until;
  final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  while (baseBranch == null || baseBranch.trim().isEmpty) {
    stdout.write('Informe a branch de referência (ex: main, develop): ');
    baseBranch = stdin.readLineSync()?.trim();
    if (baseBranch == null || baseBranch.isEmpty) {
      print('Branch de referência obrigatória.');
    }
  }
  while (since == null) {
    stdout.write('Informe a data inicial (YYYY-MM-DD): ');
    sinceStr = stdin.readLineSync()?.trim();
    if (sinceStr != null && dateRegex.hasMatch(sinceStr)) {
      try {
        since = DateTime.parse(sinceStr);
      } catch (_) {
        print('Data inválida. Tente novamente.');
      }
    } else {
      print('Formato inválido. Exemplo: 2025-11-01');
    }
  }
  while (until == null) {
    stdout.write('Informe a data final (YYYY-MM-DD) [opcional]: ');
    untilStr = stdin.readLineSync()?.trim();
    if (untilStr == null || untilStr.isEmpty) {
      break;
    }
    if (dateRegex.hasMatch(untilStr)) {
      try {
        until = DateTime.parse(untilStr);
      } catch (_) {
        print('Data inválida. Tente novamente.');
      }
    } else {
      print('Formato inválido. Exemplo: 2025-11-12');
    }
  }
  print('\nResumo:');
  print('  Branch de referência: $baseBranch');
  print('  Data inicial: $sinceStr');
  print('  Data final: ${untilStr ?? '-'}');

  // Buscar commits para o resumo
  final args = [
    'log',
    baseBranch,
    '--pretty=format:%H|%an|%aI|%s',
    '--no-merges',
    '--since=$sinceStr',
  ];
  if (untilStr != null && untilStr.isNotEmpty) {
    args.add('--until=$untilStr');
  }
  final result =
      await Process.run('git', args, workingDirectory: Directory.current.path);
  final lines = (result.stdout as String)
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.isEmpty) {
    print('\nNenhum commit encontrado para o intervalo informado.');
  } else {
    print('\nCommits encontrados:');
    for (final line in lines) {
      final parts = line.split('|');
      if (parts.length >= 4) {
        print(
            '  - ${parts[0].substring(0, 7)} | ${parts[2].substring(0, 10)} | ${parts[1]} | ${parts[3]}');
      } else {
        print('  - $line');
      }
    }
  }
  stdout.write('\nDeseja continuar e gerar o changelog? (s/n): ');
  final confirm = stdin.readLineSync()?.trim().toLowerCase();
  if (confirm != 's' &&
      confirm != 'sim' &&
      confirm != 'y' &&
      confirm != 'yes') {
    print('Operação cancelada.');
    return;
  }
  await runGitRecoverCommand(
    projectDir: Directory.current.path,
    since: since,
    until: until,
    baseBranch: baseBranch,
  );
}
