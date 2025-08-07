import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

const String microfrontendsYamlPath = 'dev_tools/shepherd/microfrontends.yaml';

class MicrofrontendsController {
  List<Map<String, dynamic>> loadMicrofrontends() {
    final file = File(microfrontendsYamlPath);
    if (!file.existsSync()) return [];
    final doc = loadYaml(file.readAsStringSync());
    if (doc is YamlMap && doc['microfrontends'] is YamlList) {
      return List<Map<String, dynamic>>.from(
        (doc['microfrontends'] as YamlList)
            .map((e) => Map<String, dynamic>.from(e)),
      );
    }
    return [];
  }

  void saveMicrofrontends(List<Map<String, dynamic>> microfrontends) {
    final writer = YamlWriter();
    final yamlString = writer.write({'microfrontends': microfrontends});
    File(microfrontendsYamlPath).writeAsStringSync(yamlString);
  }

  void addMicrofrontend({
    required String name,
    String? path,
    String? description,
  }) {
    final microfrontends = loadMicrofrontends();
    if (microfrontends.any((m) => m['name'] == name)) {
      throw Exception('A microfrontend with this name already exists.');
    }
    microfrontends.add({
      'name': name,
      if (path != null && path.isNotEmpty) 'path': path,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
    saveMicrofrontends(microfrontends);
  }

  void removeMicrofrontendByName(String name) {
    final microfrontends = loadMicrofrontends();
    final i = microfrontends.indexWhere((m) => m['name'] == name);
    if (i == -1) throw Exception('Microfrontend not found.');
    microfrontends.removeAt(i);
    saveMicrofrontends(microfrontends);
  }

  void removeMicrofrontendByIndex(int idx) {
    final microfrontends = loadMicrofrontends();
    if (idx < 0 || idx >= microfrontends.length)
      throw Exception('Index out of range.');
    microfrontends.removeAt(idx);
    saveMicrofrontends(microfrontends);
  }
}
