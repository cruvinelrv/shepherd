import 'package:shepherd/src/utils/cli_parser.dart';
import 'package:shepherd/src/utils/shepherd_config_default.dart';
import 'package:args/args.dart';
import 'dart:io';
import 'package:shepherd/src/tools/presentation/cli/command_registry.dart';
import 'package:shepherd/src/menu/presentation/cli/menu.dart'
    show printShepherdHelp;
import 'package:shepherd/src/init/presentation/cli/init_controller.dart';
import 'package:shepherd/src/sync/presentation/cli/sync_controller.dart';
import 'package:shepherd/src/sync/presentation/commands/debug_command.dart';
import 'package:shepherd/src/menu/presentation/cli/general_menu.dart';
import 'package:shepherd/src/sync/domain/services/path_validator_service.dart';
import 'package:shepherd/src/utils/config_utils.dart' show isDebugModeEnabled;

Future<void> runShepherd(List<String> arguments) async {
  final parser = buildShepherdArgParser();
  final registry = buildCommandRegistry();
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

  // Centralized validation of essential files
  if (isDebugModeEnabled()) {
    debugEssentialFiles();
  }
  final ok = await PathValidatorService.validateAndInitProjectIfNeeded(
    essentialShepherdFiles,
    registry,
  );
  if (!ok) exit(1);

  if (command == null) {
    // If no command is passed: open main interactive menu
    await showGeneralMenuLoop();
    return;
  }

  // Initialize controllers if necessary
  InitController? initController;
  SyncController? syncController;
  if (configRequiredCommands.contains(command.name)) {
    initController = InitController();
    syncController = SyncController();
    await syncController.ensureActiveUser();
    await initController.handleDbAndYamlInit(File('.shepherd/shepherd.db'), []);
    await syncController.checkAndSyncYamlDbConsistency(Directory.current.path);
  }

  // Execute command from registry
  final handler = registry[command.name];
  if (handler != null) {
    await handler(command.arguments);
    return;
  }

  stderr.writeln('Unknown command: \x1B[31m${command.name}\x1B[0m');
  printShepherdHelp();
  exit(1);
}
