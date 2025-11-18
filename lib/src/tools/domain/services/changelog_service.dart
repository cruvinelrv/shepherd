import '../usecases/update_changelog_for_update_usecase.dart';
import 'dart:io';
import '../usecases/update_changelog_for_change_usecase.dart';
import '../repositories/i_changelog_repository.dart';
import '../../data/repositories/changelog_repository.dart';
import '../../data/datasources/file_changelog_datasource.dart';
import '../../data/datasources/git_datasource.dart';
import '../../data/datasources/pubspec_datasource.dart';
import '../../presentation/cli/changelog_cli.dart';

/// Main changelog service facade - maintains backward compatibility
class ChangelogService {
  // Grouped private fields
  late final UpdateChangelogForUpdateUseCase _updateUseCase;
  late final UpdateChangelogForChangeUseCase _changeUseCase;
  late final ChangelogCli _cli;

  /// Copies CHANGELOG.md from the reference branch using git checkout
  Future<void> copyChangelogFromReference(String referenceBranch,
      {String? projectDir}) async {
    final dir = projectDir ?? Directory.current.path;
    final result = await Process.run(
      'git',
      ['checkout', referenceBranch, '--', 'CHANGELOG.md'],
      workingDirectory: dir,
    );
    if (result.exitCode != 0) {
      print('Warning: Could not copy CHANGELOG.md from $referenceBranch.');
    } else {
      print('CHANGELOG.md copied from $referenceBranch.');
    }
  }

  /// Updates the changelog header to the specified version
  Future<void> updateChangelogHeader(String version,
      {String changelogPath = 'CHANGELOG.md'}) async {
    // Always updates the first line to the new version
    final file = File(changelogPath);
    if (!await file.exists()) return;
    final lines = await file.readAsLines();
    if (lines.isNotEmpty) {
      lines[0] = '# CHANGELOG [$version]';
      await file.writeAsString(lines.join('\n'));
    }
  }

  // Expose cli as a public getter
  ChangelogCli get cli => _cli;

  ChangelogService() {
    // Initialize dependencies using DDD architecture
    final fileDataSource = FileChangelogDatasource();
    final gitDataSource = GitDatasource();
    final pubspecDataSource = PubspecDatasource(fileDataSource);
    final IChangelogRepository repository = ChangelogRepository(
      fileDataSource,
      gitDataSource,
      pubspecDataSource,
    );
    _changeUseCase = UpdateChangelogForChangeUseCase(repository);
    _updateUseCase = UpdateChangelogForUpdateUseCase(repository);
    _cli = ChangelogCli();
  }

  /// Updates the project's CHANGELOG.md, maintaining backward compatibility
  Future<List<String>> updateChangelog({
    String? baseBranch,
    String? projectDir,
    List<String>? environments,
    String? changelogType,
  }) async {
    try {
      final dir = projectDir ?? Directory.current.path;
      final branch = baseBranch ?? await _cli.promptBaseBranch();
      final type = changelogType ?? await _cli.promptChangelogType();
      if (type == 'update') {
        // Usa o usecase de update para copiar o changelog da branch de referência
        await _updateUseCase.execute(
          projectDir: dir,
          baseBranch: branch,
        );
        // Atualiza o cabeçalho do changelog para a versão atual do pubspec.yaml
        final pubspecFile = File('pubspec.yaml');
        String? version;
        if (pubspecFile.existsSync()) {
          final lines = pubspecFile.readAsLinesSync();
          final versionLine = lines.firstWhere(
            (l) => l.trim().startsWith('version:'),
            orElse: () => '',
          );
          if (versionLine.isNotEmpty) {
            version = versionLine.split(':').last.trim();
          }
        }
        if (version != null && version.isNotEmpty) {
          await updateChangelogHeader(version);
        }
        return [dir];
      } else {
        return await _changeUseCase.execute(
          projectDir: dir,
          baseBranch: branch,
        );
      }
    } catch (e) {
      _cli.showError(e.toString());
      rethrow;
    }
  }
}
