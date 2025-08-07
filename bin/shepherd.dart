import 'package:shepherd/src/config/presentation/commands/version_command.dart';
import 'package:shepherd/src/config/presentation/commands/about_command.dart';
import 'dart:io';
import 'package:args/args.dart';
import 'package:shepherd/src/tools/tools.dart';
import 'package:shepherd/src/menu/presentation/cli/general_menu.dart' show showGeneralMenuLoop;
import 'package:shepherd/src/menu/presentation/cli/menu.dart' show printShepherdHelp;
import 'package:shepherd/src/init/presentation/cli/init_controller.dart';
import 'package:shepherd/src/sync/presentation/cli/sync_controller.dart';
import 'package:shepherd/src/menu/presentation/cli/domains_menu.dart' show showDomainsMenuLoop;
import 'package:shepherd/src/menu/presentation/cli/config_menu.dart' show showConfigMenuLoop;
import 'package:shepherd/src/menu/presentation/cli/tools_menu.dart' show showToolsMenuLoop;
import 'package:shepherd/src/menu/presentation/cli/deploy_menu.dart' show runDeployStepByStep;
import 'package:shepherd/src/tools/presentation/cli/command_registry.dart';
import 'package:shepherd/src/domains/presentation/commands/analyze_command.dart'
    show runAnalyzeCommand;
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

void main(List<String> arguments) {
  runShepherd(arguments);
}

Future<void> runShepherd(List<String> arguments) async {
  final parser = ArgParser();

  final shepherdDbPath = File('shepherd.db');
  final yamlFiles = Directory.current.listSync().where((f) => f.path.endsWith('.yaml')).toList();

  // Use InitController for shepherd.db and YAMLs initialization
  final initController = InitController();
  await initController.handleDbAndYamlInit(shepherdDbPath, yamlFiles);

  // Use SyncController for shepherd.db <-> YAMLs consistency
  final syncController = SyncController();
  await syncController.checkAndSyncYamlDbConsistency(Directory.current.path);

  // Default interactive menu
  if (arguments.isEmpty || (arguments.length == 1 && arguments[0] == 'menu')) {
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

  // Interactive commands
  if (command.name == 'init' && command.arguments.isEmpty) {
    await initController.handleInit();
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
      runFormatCommand: (args) async => print('Format command not implemented.'),
      runAzureCliInstallCommand: (args) async => print('Azure CLI install not implemented.'),
      runGithubCliInstallCommand: (args) async => print('GitHub CLI install not implemented.'),
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

  // Direct commands
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
