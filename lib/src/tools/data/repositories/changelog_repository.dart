import '../../domain/entities/changelog_entities.dart';
import '../../domain/repositories/i_changelog_repository.dart';
import '../datasources/file_changelog_datasource.dart';
import '../datasources/git_datasource.dart';
import '../datasources/pubspec_datasource.dart';

/// Repository implementation for changelog operations
class ChangelogRepository implements IChangelogRepository {
  final FileChangelogDatasource _fileDataSource;
  final GitDatasource _gitDataSource;
  final PubspecDatasource _pubspecDataSource;

  ChangelogRepository(
    this._fileDataSource,
    this._gitDataSource,
    this._pubspecDataSource,
  );

  @override
  Future<List<ChangelogEntry>> getCommits({
    required String projectDir,
    required String baseBranch,
  }) async {
    return _gitDataSource.getCommits(
      projectDir: projectDir,
      baseBranch: baseBranch,
    );
  }

  @override
  Future<ProjectVersion> getCurrentVersion(String projectDir) async {
    return _pubspecDataSource.getVersion(projectDir);
  }

  @override
  Future<bool> isMicrofrontendsProject(String projectDir) async {
    return _pubspecDataSource.hasMicrofrontends(projectDir);
  }

  @override
  Future<List<MicrofrontendConfig>> getMicrofrontends(String projectDir) async {
    return _pubspecDataSource.getMicrofrontends(projectDir);
  }

  @override
  Future<String> readChangelog(String projectDir) async {
    final changelogPath = '$projectDir/CHANGELOG.md';
    return _fileDataSource.readFile(changelogPath);
  }

  @override
  Future<void> writeChangelog(String projectDir, String content) async {
    final changelogPath = '$projectDir/CHANGELOG.md';
    await _fileDataSource.writeFile(changelogPath, content);
  }

  @override
  Future<void> archiveOldChangelog(String projectDir, String content) async {
    final historyPath = '$projectDir/dev_tools/changelog_history.md';

    // Ensure dev_tools directory exists
    await _fileDataSource.createDirectory('$projectDir/dev_tools');

    // Read existing history
    final existingHistory = await _fileDataSource.readFile(historyPath);

    // Prepare new history content
    final newHistoryContent =
        existingHistory.isEmpty ? '# CHANGELOG HISTORY\n\n$content' : '$existingHistory\n$content';

    await _fileDataSource.writeFile(historyPath, newHistoryContent);
  }

  @override
  Future<bool> needsUpdate(String projectDir, String newVersion) async {
    final changelog = await readChangelog(projectDir);

    if (changelog.isEmpty) {
      return true; // Always update if no changelog exists
    }

    // Check if version already exists in changelog
    final versionPattern = RegExp(r'# CHANGELOG \[([^\]]+)\]');
    final match = versionPattern.firstMatch(changelog);

    if (match == null) {
      return true; // No version header found
    }

    final currentVersion = match.group(1);
    return currentVersion != newVersion;
  }

  @override
  Future<String> getCurrentBranch(String projectDir) async {
    return await _gitDataSource.getCurrentBranch(projectDir);
  }
}
