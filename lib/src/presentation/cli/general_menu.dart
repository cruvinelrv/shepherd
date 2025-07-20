import 'dart:io';
import 'init/init_menu.dart';
import 'domains_menu.dart';
import 'config_menu.dart';
import 'tools_menu.dart';
import 'deploy_menu.dart';
import 'user_active_utils.dart';
import 'package:shepherd/src/data/datasources/local/shepherd_database.dart';
import 'package:shepherd/src/presentation/commands/commands.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';

Future<void> showGeneralMenuLoop() async {
  final db = ShepherdDatabase(Directory.current.path);
  Map<String, dynamic>? activeUser = await readActiveUser();
  if (activeUser == null) {
    try {
      activeUser = await selectAndSetActiveUser(db);
    } catch (e) {
      print('No users registered. Please add a user first.');
      exit(1);
    }
  }
  while (true) {
    // Simple styled title and subtitle with ASCII box
    print('');
    print(
        '${AnsiColors.brightBlue}+------------------------------------------+${AnsiColors.reset}');
    print(
        '${AnsiColors.brightBlue}|${AnsiColors.reset} ${AnsiColors.brightCyan}Shepherd CLI - DDD Project Manager${AnsiColors.reset} ${AnsiColors.brightBlue}|${AnsiColors.reset}');
    print(
        '${AnsiColors.brightBlue}+------------------------------------------+${AnsiColors.reset}\n');
    final userName = '${activeUser['first_name']} ${activeUser['last_name']}';
    print(
        '${AnsiColors.bold}${AnsiColors.brightYellow}Active user:${AnsiColors.reset} ${AnsiColors.brightGreen}$userName${AnsiColors.reset}\n');
    print(
        '${AnsiColors.brightBlue}══════════════════════════════════════════════════════${AnsiColors.reset}');
    print('${AnsiColors.bold}1.${AnsiColors.reset} Domains');
    print('${AnsiColors.bold}2.${AnsiColors.reset} Config');
    print('${AnsiColors.bold}3.${AnsiColors.reset} Deploy');
    print('${AnsiColors.bold}4.${AnsiColors.reset} Tools');
    print('${AnsiColors.bold}5.${AnsiColors.reset} Init');
    print('${AnsiColors.bold}0.${AnsiColors.reset} Exit');
    print(
        '${AnsiColors.brightBlue}══════════════════════════════════════════════════════${AnsiColors.reset}');
    stdout.write('${AnsiColors.brightCyan}Select an option:${AnsiColors.reset} ');
    final input = stdin.readLineSync();
    print('');
    switch (input?.trim()) {
      case '1':
        await showDomainsMenuLoop(
          runAnalyzeCommand: runAnalyzeCommand,
          runAddOwnerCommand: runAddOwnerCommand,
          runListCommand: runListCommand,
          runExportYamlCommand: runExportYamlCommand,
          runDeleteCommand: runDeleteCommand,
        );
        break;
      case '2':
        await showConfigMenuLoop(
          runConfigCommand: runConfigCommand,
        );
        break;
      case '3':
        await showDeployMenuLoop(
          runChangelogCommand: runChangelogCommand,
          runAzureOpenPrCommand: runAzureOpenPrCommand,
        );
        break;
      case '4':
        await showToolsMenuLoop(
          runCleanCommand: runCleanCommand,
          runLinterCommand: runLinterCommand,
          runFormatCommand: runFormatCommand,
          runAzureCliInstallCommand: runAzureCliInstallCommand,
          runGithubCliInstallCommand: runGithubCliInstallCommand,
        );
        break;
      case '5':
        await showInitMenu();
        break;
      case '0':
        print('Exiting Shepherd CLI.');
        exit(0);
      default:
        print('Invalid option. Please try again.');
    }
  }
}
