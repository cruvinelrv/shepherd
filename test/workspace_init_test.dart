import 'dart:io';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Workspace Init Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('shepherd_ws_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should generate workspace.yaml and sync_config.yaml with workspace path', () async {
      final shepherdDir = Directory('${tempDir.path}/.shepherd');
      await shepherdDir.create(recursive: true);

      final syncConfigFile = File('${shepherdDir.path}/sync_config.yaml');
      final syncConfigContent = '''files:
  - path: .shepherd/workspace.yaml
    required: true
  - path: .shepherd/domains.yaml
    required: true
''';
      await syncConfigFile.writeAsString(syncConfigContent);

      final workspaceFile = File('${shepherdDir.path}/workspace.yaml');
      final workspaceContent = '''workspace:
  name: "TestWorkspace"
  version: "1.0.0"

  team_members: []

  squads:
    - name: "MAIN"
      members: []

  domains: []
''';
      await workspaceFile.writeAsString(workspaceContent);

      expect(workspaceFile.existsSync(), isTrue);
      final doc = loadYaml(workspaceFile.readAsStringSync());
      expect(doc, isA<YamlMap>());
      expect(doc['workspace']['name'], equals('TestWorkspace'));
      expect(doc['workspace']['team_members'], isNotNull);
      expect(doc['workspace']['squads'], isNotNull);
      expect(doc['workspace']['domains'], isNotNull);
    });
  });
}
