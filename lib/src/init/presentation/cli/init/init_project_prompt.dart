import 'package:shepherd/src/presentation/cli/input_utils.dart';
import 'init_cancel_exception.dart';
import 'dart:math';

String _generateSimpleUuid() {
  final rand = Random();
  return List.generate(32, (_) => rand.nextInt(16).toRadixString(16)).join();
}

Future<Map<String, String>?> promptProjectInfo(
    {bool allowCancel = false}) async {
  String? projectName;
  while (true) {
    projectName = readLinePrompt(
        'Enter the project name${allowCancel ? " (9 to return to main menu)" : ""}: ');
    if (projectName == null) continue;
    final trimmed = projectName.trim();
    if (allowCancel && trimmed == '9') {
      throw ShepherdInitCancelled();
    }
    if (trimmed.isEmpty) {
      print('Project name cannot be empty.');
      continue;
    }
    // Generate a unique id for the project
    final id = _generateSimpleUuid();
    return {'id': id, 'name': trimmed};
  }
}
