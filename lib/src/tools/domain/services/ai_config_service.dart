import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import '../../../utils/shepherd_dir_gitignore.dart';

/// Local AI provider configuration for `shepherd ai`. Lives in `.shepherd/`
/// — same directory `workspace.yaml`/`project.yaml` already use, and the
/// same one Shepherd Studio writes `workspace.yaml` into — but as its own
/// gitignored file, since unlike those, this one holds a real secret (the
/// API key).
class AiConfig {
  final String provider;
  final String model;
  final String apiKey;

  const AiConfig({
    required this.provider,
    required this.model,
    required this.apiKey,
  });
}

class AiConfigService {
  File _configFile() => File('.shepherd/ai_config.yaml');

  AiConfig? load() {
    final file = _configFile();
    if (!file.existsSync()) return null;

    final content = file.readAsStringSync();
    if (content.trim().isEmpty) return null;

    final loaded = loadYaml(content);
    if (loaded is! YamlMap) return null;

    final provider = loaded['provider'] as String?;
    final model = loaded['model'] as String?;
    final apiKey = loaded['apiKey'] as String?;
    if (provider == null || model == null || apiKey == null) return null;

    return AiConfig(provider: provider, model: model, apiKey: apiKey);
  }

  void save(AiConfig config) {
    final file = _configFile();
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    ensureShepherdGitignoreEntries(['ai_config.yaml']);

    final writer = YamlWriter();
    final yamlString = writer.write({
      'provider': config.provider,
      'model': config.model,
      'apiKey': config.apiKey,
    });
    file.writeAsStringSync(yamlString);
  }
}
