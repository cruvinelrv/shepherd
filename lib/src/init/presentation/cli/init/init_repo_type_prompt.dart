import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

import 'package:shepherd/src/menu/presentation/cli/input_utils.dart';
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
  // Save to config.yaml
  final shepherdDir = Directory('.shepherd');
  if (!shepherdDir.existsSync()) {
    shepherdDir.createSync(recursive: true);
  }
  final configFile = File('.shepherd/config.yaml');
  Map config = {};
  if (configFile.existsSync()) {
    try {
      final content = configFile.readAsStringSync();
      final map = loadYaml(content);
      if (map is Map) config = Map.from(map);
    } catch (_) {}
  }
  config['repoType'] = repoType;
  final writer = YamlWriter();
  configFile.writeAsStringSync(writer.write(config), mode: FileMode.write);
  print('Repository type "$repoType" saved in .shepherd/config.yaml');
  return repoType;
}
