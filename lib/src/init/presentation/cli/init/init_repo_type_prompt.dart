import 'dart:io';
import 'dart:convert';

import 'package:shepherd/src/presentation/cli/input_utils.dart';
import 'init_cancel_exception.dart';

Future<String?> promptRepoTypeAndSave({bool allowCancel = false}) async {
  String repoType = '';
  while (repoType != 'github' && repoType != 'azure') {
    final input = readLinePrompt(
        'Repository type (github/azure${allowCancel ? " (9 to return to main menu)" : ""}): ');
    if (input == null) continue;
    if (allowCancel && input.trim() == '9') {
      throw ShepherdInitCancelled();
    }
    repoType = input.toLowerCase();
    if (repoType != 'github' && repoType != 'azure') {
      print('Please enter "github" or "azure".');
    }
  }
  // Save to config.json
  final shepherdDir = Directory('.shepherd');
  if (!shepherdDir.existsSync()) {
    shepherdDir.createSync(recursive: true);
  }
  final configFile = File('.shepherd/config.json');
  Map<String, dynamic> config = {};
  if (configFile.existsSync()) {
    try {
      config = jsonDecode(configFile.readAsStringSync());
    } catch (_) {}
  }
  config['repoType'] = repoType;
  configFile.writeAsStringSync(jsonEncode(config), mode: FileMode.write);
  print('Repository type "$repoType" saved in .shepherd/config.json');
  return repoType;
}
