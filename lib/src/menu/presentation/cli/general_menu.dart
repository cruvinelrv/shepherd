import 'dart:io';
import 'package:shepherd/src/domains/presentation/commands/analyze_command.dart'
    show runAnalyzeCommand;
import 'package:shepherd/src/tools/domain/services/update_checker_service.dart';
import 'package:shepherd/src/domains/presentation/commands/add_owner_command.dart'
    show runAddOwnerCommand;
import 'package:shepherd/src/domains/presentation/commands/list_command.dart' show runListCommand;
import 'package:shepherd/src/sync/presentation/commands/export_yaml_command.dart'
    show runExportYamlCommand;
import 'package:shepherd/src/domains/presentation/commands/delete_domain_command.dart'
    show runDeleteCommand;
import 'package:shepherd/src/config/presentation/commands/config_command.dart'
    show runConfigCommand;
import 'package:shepherd/src/deploy/presentation/controllers/changelog_command.dart'
    show runChangelogCommand;
import 'package:shepherd/src/deploy/presentation/controllers/azure_pr_command.dart'
    show runAzureOpenPrCommand;
import 'package:shepherd/src/tools/presentation/commands/clean_command.dart' show runCleanCommand;
import 'package:shepherd/src/tools/presentation/cli/commands/format_command.dart';
import 'package:shepherd/src/tools/presentation/cli/commands/linter_command.dart';
import 'package:shepherd/src/tools/presentation/cli/commands/azurecli_command.dart';
import 'package:shepherd/src/tools/presentation/cli/commands/github_cli_install_command.dart';
import 'domains_menu.dart';
import 'config_menu.dart';
import 'tools_menu.dart';
import 'deploy_menu.dart';
import 'user_active_utils.dart';
import 'package:shepherd/src/config/data/datasources/local/config_database.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';

Future<void> showGeneralMenuLoop() async {
  final db = ConfigDatabase(Directory.current.path);
  Map<String, dynamic>? activeUser = await readActiveUser();

  // Check for updates (non-blocking, uses cache)
  String? updateMessage;
  try {
    final updateService = UpdateCheckerService(projectPath: Directory.current.path);
    final result = await updateService.checkAndHandle();
    if (result.updateAvailable && result.version != null) {
      updateMessage =
          'UPDATE AVAILABLE: ${result.version!.current} -> ${result.version!.latest} 🚀';
    }
  } catch (_) {
    // Silent fail for menu display
  }

  if (activeUser == null) {
    try {
      activeUser = await selectAndSetActiveUser(db);
    } catch (e) {
      // Show update notification even if no users are registered
      if (updateMessage != null) {
        print('\n${AnsiColors.brightYellow}$updateMessage${AnsiColors.reset}\n');
      }
      print('No users registered. Please execute "shepherd init" to add a user.');
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

    if (updateMessage != null) {
      final padding = 40 - updateMessage.length;
      final leftPad = padding ~/ 2;
      final rightPad = padding - leftPad;
      print(
          '${AnsiColors.brightBlue}|${AnsiColors.reset} ${AnsiColors.brightYellow}${' ' * leftPad}$updateMessage${' ' * rightPad}${AnsiColors.reset} ${AnsiColors.brightBlue}|${AnsiColors.reset}');
    }

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
      case '0':
        print('Exiting Shepherd CLI.');
        exit(0);
      default:
        print('Invalid option. Please try again.');
    }
  }
}
