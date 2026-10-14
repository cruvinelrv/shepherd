import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

import 'package:shepherd/src/menu/presentation/cli/input_utils.dart';
import 'init_cancel_exception.dart';
import '../../../../i18n/i18n.dart';

Future<String?> promptRepoTypeAndSave({bool allowCancel = false}) async {
  String repoType = '';
  while (repoType != 'github' && repoType != 'azure') {
    final input = readLinePrompt(
        t('init.repo_type', {'back': allowCancel ? t('init.back_hint') : ''}));
    if (input == null) continue;
    if (allowCancel && input.trim() == '9') {
      throw ShepherdInitCancelled();
    }
    repoType = input.toLowerCase();
    if (repoType != 'github' && repoType != 'azure') {
      print(t('init.repo_type_retry'));
    }
  }

  // Prompt for pullRequestEnabled
  String? prInput;
  bool pullRequestEnabled = false;
  while (true) {
    prInput = readLinePrompt(t('init.pr_ask'));
    if (prInput == null || prInput.trim().isEmpty) {
      pullRequestEnabled = false;
      break;
    }
    final resp = prInput.trim().toLowerCase();
    if (const {'s', 'sim', 'si', 's\u00ed', 'y', 'yes'}.contains(resp)) {
      pullRequestEnabled = true;
      break;
    } else if (const {'n', 'nao', 'n\u00e3o', 'no'}.contains(resp)) {
      pullRequestEnabled = false;
      break;
    } else if (allowCancel && resp == '9') {
      throw ShepherdInitCancelled();
    } else {
      print(t('init.pr_retry'));
    }
  }

  // save in config.yaml
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
  config['pullRequestEnabled'] = pullRequestEnabled;
  final writer = YamlWriter();
  configFile.writeAsStringSync(writer.write(config), mode: FileMode.write);
  print(t('init.saved', {'type': repoType, 'pr': pullRequestEnabled}));
  return repoType;
}
