import 'package:shepherd/src/tools/presentation/cli/shepherd_runner.dart';
import 'package:shepherd/src/sync/presentation/commands/validate_paths_command.dart';

void main(List<String> arguments) async {
  await validatePathsCommand([]);
  await runShepherd(arguments);
}
