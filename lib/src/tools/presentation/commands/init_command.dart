import 'dart:io';

import '../../../init/presentation/cli/init_controller.dart';

/// `shepherd init`: the standard project, with a few questions that have defaults.
Future<void> runInitCommand(List<String> args) async {
  final code = await InitController().handleInit(args: args);
  if (code != 0) exitCode = code;
}
