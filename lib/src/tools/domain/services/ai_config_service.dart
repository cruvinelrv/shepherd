import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import '../../data/models/ai_config_model.dart';
import '../../domain/entities/ai_config_entity.dart';
import '../../../utils/shepherd_dir_gitignore.dart';

export '../../domain/entities/ai_config_entity.dart';
export '../../data/models/ai_config_model.dart';

/// Backwards-compatibility alias
typedef AiConfig = AiConfigModel;

class AiConfigService {
  File _localConfigFile() => File('.shepherd/ai_config.yaml');

  File _globalConfigFile() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return File(p.join(home, '.shepherd', 'ai_config.yaml'));
  }

  /// Loads configuration from the local project `.shepherd/ai_config.yaml`
  /// or falls back to the global `~/.shepherd/ai_config.yaml` if the local does not exist.
  AiConfigModel? load({bool checkGlobal = true}) {
    final local = _localConfigFile();
    if (local.existsSync()) {
      final parsed = _loadFile(local);
      if (parsed != null) return parsed;
    }

    if (checkGlobal) {
      final global = _globalConfigFile();
      if (global.existsSync()) {
        return _loadFile(global);
      }
    }

    return null;
  }

  AiConfigModel? _loadFile(File file) {
    try {
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return null;
      final loaded = loadYaml(content);
      return AiConfigModel.fromYaml(loaded);
    } catch (_) {
      return null;
    }
  }

  /// Saves configuration to the local `.shepherd/ai_config.yaml` of the current project
  /// or globally when [global] is true.
  void save(AiConfigEntity config, {bool global = false}) {
    final file = global ? _globalConfigFile() : _localConfigFile();
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    if (!global) {
      ensureShepherdGitignoreEntries(['ai_config.yaml']);
    }

    final model = config is AiConfigModel
        ? config
        : AiConfigModel(
            activeProvider: config.activeProvider,
            activeModel: config.activeModel,
            providers: config.providers,
          );

    final writer = YamlWriter();
    final yamlString = writer.write(model.toMap());
    file.writeAsStringSync(yamlString);
  }
}
