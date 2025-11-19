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

  /// Copies CHANGELOG.md from the reference branch using git show, auto-detecting case and path
  Future<void> copyChangelogFromReference(String referenceBranch,
      {String? projectDir}) async {
    final dir = projectDir ?? Directory.current.path;
    // Check if git is available
    final gitCheck = await Process.run('git', ['--version']);
    if (gitCheck.exitCode != 0) {
      print('Error: git is not installed or not available in PATH.');
      return;
    }
    // 1. Detect the correct path/case for changelog in the branch
    final lsTree = await Process.run(
      'git',
      ['ls-tree', '-r', referenceBranch, '--name-only'],
      workingDirectory: dir,
    );
    if (lsTree.exitCode != 0) {
      print('Warning: Could not list files in $referenceBranch.');
      return;
    }
    final lsTreeOutput = (lsTree.stdout as String).split('\n');
    final changelogPath = lsTreeOutput.firstWhere(
      (line) => line.trim().toLowerCase() == 'changelog.md',
      orElse: () => '',
    );
    if (changelogPath.isEmpty) {
      print('Warning: CHANGELOG.md not found in $referenceBranch.');
      return;
    }
    // 2. Use the detected path/case in git show
    final result = await Process.run(
      'git',
      ['show', '$referenceBranch:$changelogPath'],
      workingDirectory: dir,
    );
    if (result.exitCode != 0) {
      print('Warning: Could not copy $changelogPath from $referenceBranch.');
    } else {
      final file = File('$dir/CHANGELOG.md');
      await file.writeAsString(result.stdout);
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
        await _updateUseCase.execute(
          projectDir: dir,
          baseBranch: branch,
        );
        final repo = ChangelogRepository(
          FileChangelogDatasource(),
          GitDatasource(),
          PubspecDatasource(FileChangelogDatasource()),
        );
        final versionStr = await repo.getProjectVersionWithFallback(dir);
        if (versionStr != null && versionStr.isNotEmpty) {
          await updateChangelogHeader(versionStr);
        } else {
          throw Exception(
              'pubspec.yaml not found in root or in the first microfrontend.');
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
