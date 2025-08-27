import 'dart:io';
import 'package:shepherd/src/tools/presentation/cli/shepherd_runner.dart';

/// Serviço para rotear comandos Shepherd de forma programática.
class RouterCommandService {
  /// Executa um comando Shepherd, como 'pull', 'dashboard', etc.
  Future<void> execute(String command, {List<String> arguments = const []}) async {
    final args = [command, ...arguments];
    await runShepherd(args);
  }

  /// Pergunta ao usuário se deseja executar determinado comando.
  Future<void> promptAndExecute(String command,
      {String? message, List<String> arguments = const []}) async {
    stdout.write(message ?? 'Deseja executar "$command"? [s/N]: ');
    final response = stdin.readLineSync();
    if (response != null && response.trim().toLowerCase() == 's') {
      await execute(command, arguments: arguments);
    }
  }
}
