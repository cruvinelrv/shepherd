import 'dart:io';
import '../../domain/entities/changelog_entities.dart';
import '../../domain/repositories/i_changelog_repository.dart';
import '../datasources/file_changelog_datasource.dart';
import '../datasources/git_datasource.dart';
import '../datasources/pubspec_datasource.dart';

/// Repository implementation for changelog operations
class ChangelogRepository implements IChangelogRepository {
  @override
  Future<void> copyChangelogFromBranch(
      String projectDir, String baseBranch) async {
    // Detect correct case/path for CHANGELOG.md in the reference branch
    final lsTree = await Process.run(
      'git',
      ['ls-tree', '-r', baseBranch, '--name-only'],
      workingDirectory: projectDir,
    );
    if (lsTree.exitCode != 0) {
      throw Exception('Could not list files in $baseBranch: ${lsTree.stderr}');
    }
    final files = (lsTree.stdout as String).split('\n');
    final changelogPath = files.firstWhere(
      (line) => line.trim().toLowerCase() == 'changelog.md',
      orElse: () => '',
    );
    if (changelogPath.isEmpty) {
      throw Exception('CHANGELOG.md not found in $baseBranch');
    }
    // Use git to get the changelog content from the reference branch (with correct path/case)
    final changelogContent = await _gitDataSource.getFileFromBranch(
      projectDir: projectDir,
      branch: baseBranch,
      filePath: changelogPath,
    );
    // Write the copied content to the current changelog
    await _fileDataSource.writeFile(
        '$projectDir/CHANGELOG.md', changelogContent);
  }

  @override
  Future<void> updateChangelogHeader(String projectDir, String version) async {
    final changelogPath = '$projectDir/CHANGELOG.md';
    final content = await _fileDataSource.readFile(changelogPath);
    if (content.isEmpty) return;
    final lines = content.split('\n');
    if (lines.isNotEmpty) {
      lines[0] = '# CHANGELOG [$version]';
      await _fileDataSource.writeFile(changelogPath, lines.join('\n'));
    }
  }

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

    String newHistoryContent;
    if (existingHistory.isEmpty) {
      // If no existing history, create new file with header
      newHistoryContent = '# CHANGELOG HISTORY\n\n$content';
    } else {
      // Insert new content after the header (at the beginning)
      final lines = existingHistory.split('\n');
      final headerIndex =
          lines.indexWhere((line) => line.startsWith('# CHANGELOG HISTORY'));

      if (headerIndex != -1 && lines.length > headerIndex + 1) {
        // Insert after header and empty line
        final insertIndex = headerIndex + 2;
        lines.insert(insertIndex, content);
        lines.insert(insertIndex + 1, ''); // Add separator line
        newHistoryContent = lines.join('\n');
      } else {
        // Fallback: add at the beginning
        newHistoryContent =
            '# CHANGELOG HISTORY\n\n$content\n\n$existingHistory';
      }
    }

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
