import 'dart:io';
import '../../../shepherd.dart';
import '../../utils/project_utils.dart';
import '../../domain/services/changelog_service.dart';
import '../../domain/usecases/analyze_usecase.dart';
import '../../domain/usecases/delete_usecase.dart';
import '../../domain/usecases/add_owner_usecase.dart';
import '../../domain/usecases/config_usecase.dart';
import '../../domain/usecases/export_yaml_usecase.dart';
import '../../domain/usecases/list_usecase.dart';
import '../controllers/analyze_controller.dart';
import '../controllers/delete_controller.dart';
import '../controllers/add_owner_controller.dart';
import '../controllers/config_controller.dart';
import '../controllers/export_yaml_controller.dart';
import '../controllers/list_controller.dart';
import 'menu.dart';

/// Type for a CLI command handler.
typedef CommandHandler = Future<void> Function(List<String> args);

/// Returns a map of command names to their handlers.
Map<String, CommandHandler> buildCommandRegistry() {
  return {
    'delete': (args) async {
      if (args.isEmpty) {
        stderr.writeln('Usage: shepherd delete <domain>');
        exit(1);
      }
      final shepherdDb = openShepherdDb();
      final useCase = DeleteUseCase(shepherdDb);
      final controller = DeleteController(useCase);
      await controller.run(args.first);
      await shepherdDb.close();
    },
    'add-owner': (args) async {
      if (args.isEmpty) {
        stderr.writeln('Usage: shepherd add-owner <domain>');
        exit(1);
      }
      final shepherdDb = openShepherdDb();
      final useCase = AddOwnerUseCase(shepherdDb);
      final controller = AddOwnerController(useCase);
      await controller.run(args.first);
      await shepherdDb.close();
    },
    'analyze': (args) async {
      final analysisService = AnalysisService();
      final useCase = AnalyzeUseCase(analysisService);
      final controller = AnalyzeController(useCase);
      await controller.run();
    },
    'clean': (args) async {
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
        stdout.writeln('\n--- Cleaning: [36m${dir.path}[0m ---');
        final pubspecLock = File('${dir.path}/pubspec.lock');
        if (await pubspecLock.exists()) {
          await pubspecLock.delete();
          stdout.writeln('Removed pubspec.lock');
        }
        final cleanResult = await Process.run('flutter', ['clean'], workingDirectory: dir.path);
        stdout.write(cleanResult.stdout);
        stderr.write(cleanResult.stderr);
        final pubGetResult =
            await Process.run('flutter', ['pub', 'get'], workingDirectory: dir.path);
        stdout.write(pubGetResult.stdout);
        stderr.write(pubGetResult.stderr);
        stdout.writeln('--- Cleaning completed in: ${dir.path} ---');
      }
      stdout.writeln('\nCleaning finished!');
    },
    'config': (args) async {
      final shepherdDb = openShepherdDb();
      final useCase = ConfigUseCase(shepherdDb);
      final controller = ConfigController(useCase);
      await controller.run();
      await shepherdDb.close();
    },
    'list': (args) async {
      final shepherdDb = openShepherdDb();
      final useCase = ListUseCase(shepherdDb);
      final controller = ListController(useCase);
      await controller.run();
      await shepherdDb.close();
    },
    'export-yaml': (args) async {
      final shepherdDb = openShepherdDb();
      final useCase = ExportYamlUseCase(shepherdDb);
      final controller = ExportYamlController(useCase);
      await controller.run();
      await shepherdDb.close();
    },
    'changelog': (args) async {
      try {
        final service = ChangelogService();
        await service.updateChangelog();
        print('CHANGELOG.md successfully updated!');
      } catch (e) {
        print('Error updating changelog: $e');
        exit(1);
      }
    },
    'help': (args) async {
      printShepherdHelp();
    },
  };
}
