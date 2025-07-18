import 'dart:io';

import 'package:args/args.dart';
import 'package:shepherd/shepherd.dart';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/services/changelog_service.dart';
import 'package:shepherd/src/domain/usecases/add_owner_usecase.dart';
import 'package:shepherd/src/domain/usecases/analyze_usecase.dart';
import 'package:shepherd/src/domain/usecases/config_usecase.dart';
import 'package:shepherd/src/domain/usecases/delete_usecase.dart';
import 'package:shepherd/src/domain/usecases/export_yaml_usecase.dart';
import 'package:shepherd/src/domain/usecases/list_usecase.dart';
import 'package:shepherd/src/presentation/controllers/add_owner_controller.dart';
import 'package:shepherd/src/presentation/controllers/analyze_controller.dart';
import 'package:shepherd/src/presentation/controllers/config_controller.dart';
import 'package:shepherd/src/presentation/controllers/delete_controller.dart';
import 'package:shepherd/src/presentation/controllers/export_yaml_controller.dart';
import 'package:shepherd/src/presentation/controllers/list_controller.dart';
import 'package:shepherd/src/utils/cli_parser.dart';

Future<void> _runChangelogCommand() async {
  try {
    final service = ChangelogService();
    await service.updateChangelog();
    print('CHANGELOG.md successfully updated!');
  } catch (e) {
    print('Error updating changelog: $e');
    exit(1);
  }
}

Future<void> _runExportYamlCommand() async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final useCase = ExportYamlUseCase(shepherdDb);
  final controller = ExportYamlController(useCase);
  await controller.run();
  await shepherdDb.close();
}

Future<void> _runDeleteCommand(String domainName) async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final useCase = DeleteUseCase(shepherdDb);
  final controller = DeleteController(useCase);
  await controller.run(domainName);
  await shepherdDb.close();
}

Future<void> _runAddOwnerCommand(String domainName) async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final useCase = AddOwnerUseCase(shepherdDb);
  final controller = AddOwnerController(useCase);
  await controller.run(domainName);
  await shepherdDb.close();
}

void main(List<String> arguments) async {
  final parser = buildShepherdArgParser();

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    print(e.message);
    print('Usage: dart run shepherd <command> [options]');
    print(parser.usage);
    exit(1);
  }
  final command = argResults.command;

  if (command == null) {
    print('No command specified.');
    print('Usage: dart run shepherd <command> [options]');
    print(parser.usage);
    exit(1);
  }

  switch (command.name) {
    case 'analyze':
      await _runAnalyzeCommand();
      break;
    case 'clean':
      await _runCleanCommand(command.arguments);
      break;
    case 'config':
      await _runConfigCommand();
      break;
    case 'list':
      await _runListCommand();
      break;
    case 'delete':
      if (command.arguments.isEmpty) {
        print('Usage: dart run shepherd delete <domain>');
        exit(1);
      }
      await _runDeleteCommand(command.arguments.first);
      break;
    case 'add-owner':
      if (command.arguments.isEmpty) {
        print('Usage: dart run shepherd add-owner <domain>');
        exit(1);
      }
      await _runAddOwnerCommand(command.arguments.first);
      break;
    case 'export-yaml':
      await _runExportYamlCommand();
      break;
    case 'changelog':
      await _runChangelogCommand();
      break;
    case 'help':
      _printHelp();
      break;
  }
}

void _printHelp() {
  print('''
Shepherd CLI - Available commands:

  analyze              Analyze the domains of the current project.
  clean                Clean all projects (or use "project" to clean only the current one).
  config               Configure and register domains in the project.
  list                 List all domains registered in the project.
  delete <domain>      Remove a specific domain from the project.

  add-owner <domain>   Add a new person as owner of an existing domain.
  export-yaml          Export all domains and owners to the devops/domains.yaml file.
  changelog            Update the project CHANGELOG.md.
  help                 Show this help menu.

Usage examples:
  dart run shepherd analyze
  dart run shepherd clean
  dart run shepherd clean project
  dart run shepherd config
  dart run shepherd list
  dart run shepherd delete auth_domain
  dart run shepherd changelog
''');
}

Future<void> _runListCommand() async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final useCase = ListUseCase(shepherdDb);
  final controller = ListController(useCase);
  await controller.run();
  await shepherdDb.close();
}

Future<void> _runConfigCommand() async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final useCase = ConfigUseCase(shepherdDb);
  final controller = ConfigController(useCase);
  await controller.run();
  await shepherdDb.close();
}

Future<void> _runCleanCommand(List<String> args) async {
  final onlyCurrent = args.isNotEmpty && args.first == 'project';
  final root = Directory.current;
  final pubspecFiles = <File>[];

  if (onlyCurrent) {
    final pubspec = File('${root.path}/pubspec.yaml');
    if (await pubspec.exists()) {
      pubspecFiles.add(pubspec);
    } else {
      print('No pubspec.yaml found in the current directory.');
      exit(1);
    }
  } else {
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('pubspec.yaml')) {
        pubspecFiles.add(entity);
      }
    }
    if (pubspecFiles.isEmpty) {
      print('No pubspec.yaml found in the project.');
      exit(1);
    }
  }

  for (final pubspec in pubspecFiles) {
    final dir = pubspec.parent;
    print('\n--- Cleaning: \\${dir.path} ---');
    final pubspecLock = File('${dir.path}/pubspec.lock');
    if (await pubspecLock.exists()) {
      await pubspecLock.delete();
      print('Removed pubspec.lock');
    }
    final cleanResult =
        await Process.run('flutter', ['clean'], workingDirectory: dir.path);
    stdout.write(cleanResult.stdout);
    stderr.write(cleanResult.stderr);
    final pubGetResult = await Process.run('flutter', ['pub', 'get'],
        workingDirectory: dir.path);
    stdout.write(pubGetResult.stdout);
    stderr.write(pubGetResult.stderr);
    print('--- Cleaning completed in: \\${dir.path} ---');
  }
  print('\nCleaning finished!');
}

Future<void> _runAnalyzeCommand() async {
  final analysisService = AnalysisService();
  final useCase = AnalyzeUseCase(analysisService);
  final controller = AnalyzeController(useCase);
  await controller.run();
}
