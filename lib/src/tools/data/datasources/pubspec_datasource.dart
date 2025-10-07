import 'package:yaml/yaml.dart';
import '../../domain/entities/changelog_entities.dart';
import 'file_changelog_datasource.dart';

/// Pubspec and YAML operations datasource
class PubspecDatasource {
  final FileChangelogDatasource _fileDataSource;

  PubspecDatasource(this._fileDataSource);

  /// Get version from pubspec.yaml
  Future<ProjectVersion> getVersion(String projectDir) async {
    final pubspecPath = '$projectDir/pubspec.yaml';
    final content = await _fileDataSource.readFile(pubspecPath);

    if (content.isEmpty) {
      throw Exception('pubspec.yaml not found in $projectDir');
    }

    final yaml = loadYaml(content);
    final version = yaml['version']?.toString();

    if (version == null) {
      throw Exception('Version not found in pubspec.yaml');
    }

    return ProjectVersion(version: version, source: 'pubspec.yaml');
  }

  /// Check if project has microfrontends configuration
  Future<bool> hasMicrofrontends(String projectDir) async {
    final microfrontendsPath = '$projectDir/.shepherd/microfrontends.yaml';
    return _fileDataSource.fileExists(microfrontendsPath);
  }

  /// Get microfrontends configuration
  Future<List<MicrofrontendConfig>> getMicrofrontends(String projectDir) async {
    final microfrontendsPath = '$projectDir/.shepherd/microfrontends.yaml';
    final content = await _fileDataSource.readFile(microfrontendsPath);

    if (content.isEmpty) {
      return [];
    }

    final yaml = loadYaml(content);
    final microfrontends = <MicrofrontendConfig>[];

    if (yaml is Map && yaml['microfrontends'] is YamlList) {
      final mfList = yaml['microfrontends'] as YamlList;

      for (final mfConfig in mfList) {
        if (mfConfig is Map) {
          final name = mfConfig['name']?.toString() ?? '';
          final path = mfConfig['path']?.toString() ?? '';

          if (name.isNotEmpty && path.isNotEmpty) {
            microfrontends.add(MicrofrontendConfig(
              name: name,
              path: path,
              config: Map<String, dynamic>.from(mfConfig),
            ));
          }
        }
      }
    }

    return microfrontends;
  }
}
