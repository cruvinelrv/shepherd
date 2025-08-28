import 'dart:io';
import 'package:shepherd/src/tools/presentation/cli/shepherd_runner.dart';

/// Service to route Shepherd commands programmatically.
class RouterCommandService {
  /// execute command Shepherd, like 'pull', 'dashboard', etc.
  Future<void> execute(String command,
      {List<String> arguments = const []}) async {
    final args = [command, ...arguments];
    await runShepherd(args);
  }

  /// Asks the user if they want to execute a specific command.
  Future<void> promptAndExecute(String command,
      {String? message, List<String> arguments = const []}) async {
    stdout.write(message ?? 'Do you want to execute "$command"? [y/N]: ');
    final response = stdin.readLineSync();
    if (response != null && response.trim().toLowerCase() == 's') {
      await execute(command, arguments: arguments);
    }
  }
}
