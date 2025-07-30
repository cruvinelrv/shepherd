import 'package:shepherd/src/config/presentation/commands/version_command.dart'
    show runVersionCommand;
import 'package:shepherd/src/config/presentation/commands/about_command.dart'
    show runAboutCommand;
import 'dart:io';
import 'package:args/args.dart';
import 'package:shepherd/src/tools/tools.dart';
import 'package:shepherd/src/utils/cli_parser.dart';
import 'package:shepherd/src/menu/presentation/cli/menu.dart';
import 'package:shepherd/src/init/presentation/cli/init/init_menu.dart';
import 'package:shepherd/src/menu/presentation/cli/domains_menu.dart';
import 'package:shepherd/src/menu/presentation/cli/config_menu.dart';
import 'package:shepherd/src/menu/presentation/cli/tools_menu.dart';
import 'package:shepherd/src/menu/presentation/cli/deploy_menu.dart';
import 'package:shepherd/src/menu/presentation/cli/command_registry.dart';
import 'package:shepherd/src/domains/presentation/commands/analyze_command.dart'
    show runAnalyzeCommand;
import 'package:shepherd/src/domains/presentation/commands/add_owner_command.dart'
    show runAddOwnerCommand;
import 'package:shepherd/src/domains/presentation/commands/list_command.dart'
    show runListCommand;
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
import 'package:shepherd/src/tools/presentation/commands/clean_command.dart'
    show runCleanCommand;
import 'package:shepherd/src/menu/presentation/cli/general_menu.dart';

void main(List<String> arguments) async {
  final parser = buildShepherdArgParser();

  // Se não houver argumentos ou o comando for 'menu', mostra o menu interativo
  if (arguments.isEmpty || (arguments.length == 1 && arguments[0] == 'menu')) {
    // Verifica se há usuários registrados (ajuste conforme sua lógica de verificação)
    // Exemplo: if (!hasRegisteredUsers()) { print('Execute shepherd config'); return; }
    await showGeneralMenuLoop();
    return;
  }

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    print(e.message);
    print('Usage: shepherd <command> [options]');
    print(parser.usage);
    exit(1);
  }
  final command = argResults.command;

  if (command == null) {
    print('No command specified.');
    print('Usage: shepherd <group>');
    printShepherdHelp();
    exit(1);
  }

  // Comandos interativos
  if (command.name == 'init' && command.arguments.isEmpty) {
    await showInitMenu();
    return;
  }
  if (command.name == 'domains' && command.arguments.isEmpty) {
    await showDomainsMenuLoop(
      runAnalyzeCommand: runAnalyzeCommand,
      runAddOwnerCommand: runAddOwnerCommand,
      runListCommand: runListCommand,
      runExportYamlCommand: runExportYamlCommand,
      runDeleteCommand: runDeleteCommand,
    );
    return;
  }
  if (command.name == 'config' && command.arguments.isEmpty) {
    await showConfigMenuLoop(
      runConfigCommand: runConfigCommand,
    );
    return;
  }
  if (command.name == 'deploy' && command.arguments.isEmpty) {
    // Run the step-by-step flow: change version, generate changelog, open PR, etc.
    await runDeployStepByStep(
      runChangelogCommand: runChangelogCommand,
      runAzureOpenPrCommand: runAzureOpenPrCommand,
    );
    return;
  }
  if (command.name == 'tools' && command.arguments.isEmpty) {
    await showToolsMenuLoop(
      runCleanCommand: runCleanCommand,
      runLinterCommand: runLinterCommand,
      runFormatCommand: runFormatCommand,
      runAzureCliInstallCommand: runAzureCliInstallCommand,
      runGithubCliInstallCommand: runGithubCliInstallCommand,
    );
    return;
  }

  // shepherd version
  if (command.name == 'version') {
    await runVersionCommand(command.arguments);
    return;
  }
  // shepherd about
  if (command.name == 'about') {
    await runAboutCommand(command.arguments);
    return;
  }

  // Comandos diretos
  final registry = buildCommandRegistry();
  final handler = registry[command.name];
  if (handler != null) {
    await handler(command.arguments);
  } else {
    stderr.writeln('Unknown command: \x1B[31m${command.name}\x1B[0m');
    printShepherdHelp();
    exit(1);
  }
}
