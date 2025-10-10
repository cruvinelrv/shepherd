import '../entities/changelog_entities.dart';

/// Repository interface for changelog operations
abstract class IChangelogRepository {
  /// Get commits from git log for the specified branch
  Future<List<ChangelogEntry>> getCommits({
    required String projectDir,
    required String baseBranch,
  });

  /// Get current project version from pubspec.yaml
  Future<ProjectVersion> getCurrentVersion(String projectDir);

  /// Check if project is a microfrontends setup
  Future<bool> isMicrofrontendsProject(String projectDir);

  /// Get microfrontends configuration
  Future<List<MicrofrontendConfig>> getMicrofrontends(String projectDir);

  /// Read current changelog content
  Future<String> readChangelog(String projectDir);

  /// Write changelog content
  Future<void> writeChangelog(String projectDir, String content);

  /// Archive old changelog to history file
  Future<void> archiveOldChangelog(String projectDir, String content);

  /// Check if changelog needs updating (version changed)
  Future<bool> needsUpdate(String projectDir, String newVersion);

  /// Get current git branch
  Future<String> getCurrentBranch(String projectDir);
}
