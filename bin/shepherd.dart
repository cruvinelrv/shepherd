import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shepherd/src/config/presentation/commands/version_command.dart'
    show runVersionCommand;
import 'package:path/path.dart';
import 'package:shepherd/src/config/presentation/commands/about_command.dart'
    show runAboutCommand;
import 'dart:io';
import 'package:args/args.dart';
import 'package:shepherd/src/tools/tools.dart';
import 'package:shepherd/src/utils/cli_parser.dart';
import 'package:shepherd/src/menu/presentation/cli/general_menu.dart'
    show showGeneralMenuLoop;
import 'package:shepherd/src/menu/presentation/cli/menu.dart'
    show printShepherdHelp;
import 'package:shepherd/src/sync/presentation/commands/sync_config.dart';
import 'package:shepherd/src/init/presentation/cli/init/init_menu.dart';
import 'package:shepherd/src/menu/presentation/cli/domains_menu.dart';
import 'package:shepherd/src/menu/presentation/cli/config_menu.dart';
import 'package:shepherd/src/menu/presentation/cli/tools_menu.dart';
import 'package:shepherd/src/menu/presentation/cli/deploy_menu.dart';
import 'package:shepherd/src/tools/presentation/cli/command_registry.dart';
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

import 'package:shepherd/src/sync/domain/services/yaml_db_consistency_checker.dart';

void main(List<String> arguments) async {
  // Early routing for independent commands
  final parser = buildShepherdArgParser();
  ArgResults? argResults;
  String? commandName;
  List<String> commandArgs = [];
  try {
    argResults = parser.parse(arguments);
    commandName = argResults.command?.name;
    commandArgs = argResults.command?.arguments ?? [];
  } catch (_) {
    commandName = null;
  }

  // Routing must happen BEFORE any shepherd.db/YAMLs checks
  if (commandName == 'clean' || commandName == 'project') {
    final registry = buildCommandRegistry();
    final handler = registry[commandName];
    if (handler != null) {
      await handler(commandArgs);
      return;
    }
  }
  if (commandName == 'changelog') {
    final registry = buildCommandRegistry();
    final handler = registry['changelog'];
    if (handler != null) {
      await handler(commandArgs);
      return;
    }
  }
  if (commandName == 'about' || commandName == 'help') {
    final registry = buildCommandRegistry();
    final handler = registry[commandName];
    if (handler != null) {
      await handler(commandArgs);
      return;
    }
  }

  // ...rest of initialization, onboarding, sync code, etc...
  // Database path
  final shepherdDbPath =
      File(join(Directory.current.path, '.shepherd', 'shepherd.db'));
  final yamlDir =
      Directory(join(Directory.current.path, 'dev_tools', 'shepherd'));
  final yamlFiles = yamlDir.existsSync()
      ? yamlDir.listSync().where((f) => f.path.endsWith('.yaml')).toList()
      : <File>[];
  if (!shepherdDbPath.existsSync()) {
    if (yamlFiles.isNotEmpty) {
      stdout.write(
          'shepherd.db not found, but YAML files were found. Do you want to run "shepherd pull" to create the database from YAMLs? (y/N): ');
      final resp = stdin.readLineSync()?.trim().toLowerCase();
      if (resp == 's' || resp == 'sim' || resp == 'y' || resp == 'yes') {
        await Process.run('shepherd', ['pull']);
        print('shepherd pull executed.');
      } else {
        print(
            'shepherd.db will be created empty. The data from YAML files will be overwritten if you run shepherd init.');
        // Create empty shepherd.db
        final shepherdDir =
            Directory(join(Directory.current.path, '.shepherd'));
        if (!shepherdDir.existsSync()) shepherdDir.createSync(recursive: true);
        final dbFile = File(join(shepherdDir.path, 'shepherd.db'));
        dbFile.createSync();
        stdout.write(
            'Do you want to run "shepherd init" to start a new project? (y/N): ');
        final respInit = stdin.readLineSync()?.trim().toLowerCase();
        if (respInit == 's' ||
            respInit == 'sim' ||
            respInit == 'y' ||
            respInit == 'yes') {
          await showInitMenu();
          return;
        } else {
          print(
              'Operation cancelled. Empty shepherd.db created, but not initialized.');
          exit(0);
        }
      }
    } else {
      stdout.write(
          'shepherd.db and YAML files not found. Do you want to run "shepherd init" to start a new project? (y/N): ');
      final resp = stdin.readLineSync()?.trim().toLowerCase();
      if (resp == 's' || resp == 'sim' || resp == 'y' || resp == 'yes') {
        await showInitMenu();
        return;
      } else {
        print('Operation cancelled. shepherd.db was not created.');
        exit(0);
      }
    }
  } else {
    // Check if the database is empty (0 bytes) or has no tables
    bool isEmptyDb = shepherdDbPath.lengthSync() == 0;
    if (!isEmptyDb) {
      try {
        final db = await databaseFactoryFfi.openDatabase(shepherdDbPath.path,
            options: OpenDatabaseOptions(readOnly: true));
        final tables = await db
            .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        isEmptyDb = tables.isEmpty;
        await db.close();
      } catch (_) {
        isEmptyDb = true;
      }
    }
    if (isEmptyDb) {
      print('The file shepherd.db exists but is empty or has no tables.');
      while (true) {
        print('\nChoose an option to initialize the database:');
        if (yamlFiles.isNotEmpty) {
          print('[1] shepherd pull (recreate from YAMLs)');
        }
        print('[2] shepherd init (start a new project)');
        print('[3] Exit');
        stdout.write('Enter the number of the desired option: ');
        final opt = stdin.readLineSync()?.trim();
        if (opt == '1' && yamlFiles.isNotEmpty) {
          await Process.run('shepherd', ['pull']);
          print('shepherd pull executed.');
          break;
        } else if (opt == '2') {
          await showInitMenu();
          return;
        } else if (opt == '3') {
          print('Operation cancelled. shepherd.db remains empty.');
          exit(0);
        } else {
          print('Invalid option.');
        }
      }
    }
  }

  // Consistency check between shepherd.db and YAMLs
  try {
    final isConsistent = await checkYamlDbConsistency(Directory.current.path);
    if (!isConsistent) {
      print('\nThe following files are required for synchronization:');
      for (final config in syncedFiles) {
        if (config.requiredSync) {
          print('  - ${config.path}');
        }
      }
      stdout.write(
          'YAML files are not consistent with shepherd.db. Do you want to run "shepherd pull" to synchronize? (y/N): ');
      final resp = stdin.readLineSync()?.trim().toLowerCase();
      if (resp == 's' || resp == 'sim' || resp == 'y' || resp == 'yes') {
        await Process.run('shepherd', ['pull']);
        print('Synchronization completed.');
      }
    }
  } catch (e) {
    //
  }

  // (Removed, already at the beginning of the function)

  // If there are no arguments or the command is 'menu', show the interactive menu
  if (arguments.isEmpty || (arguments.length == 1 && arguments[0] == 'menu')) {
    // Check if there are registered users (adjust according to your verification logic)
    // Example: if (!hasRegisteredUsers()) { print('Run shepherd config'); return; }
    await showGeneralMenuLoop();
    return;
  }

  // ArgResults argResults; // already defined above for early routing
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
