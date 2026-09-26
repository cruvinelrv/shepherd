import 'dart:io';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/tools/domain/services/workspace_scaffold_service.dart';

void main() {
  group('WorkspaceScaffoldService Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('shepherd_scaffold_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should auto-create .shepherd directory and all workspace & project files', () async {
      WorkspaceScaffoldService.ensureShepherdFiles(basePath: tempDir.path);

      final shepherdDir = Directory('${tempDir.path}/.shepherd');
      expect(shepherdDir.existsSync(), isTrue);

      // Workspace level files
      final workspaceFile = File('${shepherdDir.path}/workspace.yaml');
      expect(workspaceFile.existsSync(), isTrue);
      final wsDoc = loadYaml(workspaceFile.readAsStringSync());
      expect(wsDoc['workspace']['name'], isNotEmpty);

      final skillsFile = File('${shepherdDir.path}/skills.yaml');
      expect(skillsFile.existsSync(), isTrue);
      final skillsDoc = loadYaml(skillsFile.readAsStringSync());
      expect(skillsDoc['skills'], isA<YamlList>());

      final domainsFile = File('${shepherdDir.path}/domains.yaml');
      expect(domainsFile.existsSync(), isTrue);

      final syncConfigFile = File('${shepherdDir.path}/sync_config.yaml');
      expect(syncConfigFile.existsSync(), isTrue);

      // Project level files
      final specsFile = File('${shepherdDir.path}/specs.yaml');
      expect(specsFile.existsSync(), isTrue);
      final specsDoc = loadYaml(specsFile.readAsStringSync());
      expect(specsDoc['specs'], isNotNull);
      expect(specsDoc['specs']['project'], isNotNull);
      expect(specsDoc['specs']['architecture'], isNotNull);

      final projectFile = File('${shepherdDir.path}/project.yaml');
      expect(projectFile.existsSync(), isTrue);

      final envsFile = File('${shepherdDir.path}/environments.yaml');
      expect(envsFile.existsSync(), isTrue);

      final togglesFile = File('${shepherdDir.path}/feature_toggles.yaml');
      expect(togglesFile.existsSync(), isTrue);

      final configFile = File('${shepherdDir.path}/config.yaml');
      expect(configFile.existsSync(), isTrue);

      final mfeFile = File('${shepherdDir.path}/microfrontends.yaml');
      expect(mfeFile.existsSync(), isTrue);

      final activityFile = File('${shepherdDir.path}/shepherd_activity.yaml');
      expect(activityFile.existsSync(), isTrue);

      final gitignoreFile = File('${shepherdDir.path}/.gitignore');
      expect(gitignoreFile.existsSync(), isTrue);
      final gitignoreContent = gitignoreFile.readAsStringSync();
      expect(gitignoreContent, contains('session.yaml'));
      expect(gitignoreContent, contains('ai_config.yaml'));
      expect(gitignoreContent, contains('shepherd.db'));
    });

    test('should not overwrite existing user files when ran again', () async {
      final shepherdDir = Directory('${tempDir.path}/.shepherd');
      await shepherdDir.create(recursive: true);

      final specsFile = File('${shepherdDir.path}/specs.yaml');
      await specsFile.writeAsString('custom_specs: true');

      final skillsFile = File('${shepherdDir.path}/skills.yaml');
      await skillsFile.writeAsString('custom_skills: true');

      WorkspaceScaffoldService.ensureShepherdFiles(basePath: tempDir.path);

      expect(specsFile.readAsStringSync(), equals('custom_specs: true'));
      expect(skillsFile.readAsStringSync(), equals('custom_skills: true'));
    });
  });
}
