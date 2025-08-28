import 'dart:io';

import '../../../../shepherd.dart';
import '../../../menu/presentation/cli/deploy_menu.dart';
import '../../../deploy/presentation/controllers/azure_pr_command.dart';
import '../../../tools/presentation/commands/dashboard_command.dart';
import '../../../menu/presentation/cli/direct_commands.dart';
import '../../../config/presentation/controllers/config_controller.dart';
import '../../../domains/domain/usecases/add_owner_usecase.dart';
import '../../../domains/domain/usecases/analyze_usecase.dart';
import '../../../domains/domain/usecases/config_usecase.dart';
import '../../../domains/domain/usecases/delete_domain_usecase.dart';
import '../../../sync/domain/usecases/export_yaml_usecase.dart';
import '../../../domains/domain/usecases/list_usecase.dart';
import '../../../domains/presentation/controllers/add_owner_controller.dart';
import '../../../domains/presentation/controllers/analyze_controller.dart';
import '../../../domains/presentation/controllers/delete_controller.dart';
import '../../../domains/presentation/controllers/list_controller.dart';
import '../../../sync/presentation/commands/pull_command.dart';
import '../../../sync/presentation/controllers/export_yaml_controller.dart';
import '../../../tools/domain/services/changelog_service.dart';
import '../../../utils/config_utils.dart';
import '../../../utils/list_utils.dart' as owner_utils;
import '../../../utils/list_utils.dart' as list_utils;
import '../../../init/presentation/cli/init_controller.dart';
import '../../../config/presentation/commands/version_command.dart';

/// Type for a CLI command handler.
typedef CommandHandler = Future<void> Function(List<String> args);

/// Returns a map of command names to their handlers.
Map<String, CommandHandler> buildCommandRegistry() {
  return {
    'dashboard': (args) async {
      await runDashboardCommand();
    },
    'project': (args) async {
      // Alias for cleaning only the current project, fully independent
      final cleanHandler = buildCommandRegistry()['clean'];
      if (cleanHandler != null) {
        await cleanHandler(['project']);
      } else {
        stderr.writeln('No handler for clean command.');
        exit(1);
      }
    },
    'pull': (args) async {
      await runPullCommand(args);
    },
    'delete': (args) async {
      if (args.isEmpty) {
        stderr.writeln('Usage: shepherd delete <domain>');
        exit(1);
      }
      final domainsDb = owner_utils.openDomainsDb();
      final useCase = DeleteDomainUseCase(domainsDb);
      final controller = DeleteController(useCase);
      await controller.run(args.first);
      await domainsDb.close();
    },
    'add-owner': (args) async {
      if (args.isEmpty) {
        stderr.writeln('Usage: shepherd add-owner <domain>');
        exit(1);
      }
      final domainsDb = owner_utils.openDomainsDb();
      final useCase = AddOwnerUseCase(domainsDb);
      final controller = AddOwnerController(useCase);
      await controller.run(args.first);
      await domainsDb.close();
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
        stdout.writeln('\n--- Cleaning: \x1B[36m${dir.path}\x1B[0m ---');
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
      final configDb = openConfigDb();
      final domainsDb = owner_utils.openDomainsDb();
      final useCase = ConfigUseCase(configDb, domainsDb);
      final controller = ConfigController(useCase);
      await controller.run();
      await configDb.close();
      await domainsDb.close();
    },
    'list': (args) async {
      final domainsDb = list_utils.openDomainsDb();
      final useCase = ListUseCase(domainsDb);
      final controller = ListController(useCase);
      await controller.run();
      await domainsDb.close();
    },
    'export-yaml': (args) async {
      final domainsDb = list_utils.openDomainsDb();
      final useCase = ExportYamlUseCase(domainsDb);
      final controller = ExportYamlController(useCase);
      await controller.run();
      await domainsDb.close();
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
      DirectCommandsMenu.printShepherdHelp();
    },
    'about': (args) async {
      DirectCommandsMenu.printShepherdAbout();
    },
    'init': (args) async {
      final initController = InitController();
      await initController.handleInit();
    },
    'deploy': (args) async {
      // execute the automated deploy flow
      await runDeployStepByStep(
        runChangelogCommand: () async {
          final service = ChangelogService();
          await service.updateChangelog();
        },
        runAzureOpenPrCommand: runAzureOpenPrCommand,
      );
    },
    'version': (args) async {
      await runVersionCommand(args);
    },
  };
}
