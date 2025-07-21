import 'dart:io';
import 'package:args/args.dart';
import 'package:shepherd/src/tools/tools.dart';
import 'package:shepherd/src/utils/cli_parser.dart';
import 'package:shepherd/src/presentation/cli/menu.dart';
import 'package:shepherd/src/presentation/cli/init/init_menu.dart';
import 'package:shepherd/src/presentation/cli/domains_menu.dart';
import 'package:shepherd/src/presentation/cli/config_menu.dart';
import 'package:shepherd/src/presentation/cli/tools_menu.dart';
import 'package:shepherd/src/presentation/cli/deploy_menu.dart';
import 'package:shepherd/src/presentation/cli/command_registry.dart';
import 'package:shepherd/src/presentation/commands/commands.dart';
import 'package:shepherd/src/presentation/cli/general_menu.dart';

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
    await showDeployMenuLoop(
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
