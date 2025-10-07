import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

import 'package:shepherd/src/menu/presentation/cli/input_utils.dart';
import 'init_cancel_exception.dart';

Future<String?> promptRepoTypeAndSave({bool allowCancel = false}) async {
  String repoType = '';
  while (repoType != 'github' && repoType != 'azure') {
    final input = readLinePrompt(
        'Tipo de repositório (github/azure${allowCancel ? " (9 para voltar ao menu principal)" : ""}): ');
    if (input == null) continue;
    if (allowCancel && input.trim() == '9') {
      throw ShepherdInitCancelled();
    }
    repoType = input.toLowerCase();
    if (repoType != 'github' && repoType != 'azure') {
      print('Por favor, digite "github" ou "azure".');
    }
  }

  // Prompt for pullRequestEnabled
  String? prInput;
  bool pullRequestEnabled = false;
  while (true) {
    prInput =
        readLinePrompt('Deseja habilitar opções de Pull Request? (s/N): ');
    if (prInput == null || prInput.trim().isEmpty) {
      pullRequestEnabled = false;
      break;
    }
    final resp = prInput.trim().toLowerCase();
    if (resp == 's' || resp == 'sim' || resp == 'y' || resp == 'yes') {
      pullRequestEnabled = true;
      break;
    } else if (resp == 'n' || resp == 'nao' || resp == 'não' || resp == 'no') {
      pullRequestEnabled = false;
      break;
    } else if (allowCancel && resp == '9') {
      throw ShepherdInitCancelled();
    } else {
      print('Please answer with "y" for yes or "n" for no.');
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
  print(
      'Tipo de repositório "$repoType" e pullRequestEnabled=$pullRequestEnabled salvos em .shepherd/config.yaml');
  return repoType;
}
