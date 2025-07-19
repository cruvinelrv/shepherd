import 'dart:io';

import 'package:args/args.dart';
import 'package:shepherd/src/utils/cli_parser.dart';
import 'package:shepherd/src/presentation/cli/menu.dart';
import 'package:shepherd/src/presentation/cli/domains_menu.dart';
import 'package:shepherd/src/presentation/cli/config_menu.dart';
import 'package:shepherd/src/presentation/cli/tools_menu.dart';
import 'package:shepherd/src/presentation/cli/deploy_menu.dart';
import 'package:shepherd/src/presentation/cli/command_registry.dart';
import 'package:shepherd/src/presentation/commands/commands.dart';

void main(List<String> arguments) async {
  final parser = buildShepherdArgParser();

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

  // Interactive group menus
  if (command == null) {
    print('No command specified.');
    print('Usage: shepherd <group>');
    printShepherdHelp();
    exit(1);
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
    );
    return;
  }
  if (command.name == 'tools' && command.arguments.isEmpty) {
    await showToolsMenuLoop(
      runCleanCommand: runCleanCommand,
    );
    return;
  }

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
