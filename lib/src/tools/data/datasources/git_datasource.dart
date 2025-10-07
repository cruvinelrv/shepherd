import 'dart:io';
import '../../domain/entities/changelog_entities.dart';

/// Git operations datasource
class GitDatasource {
  /// Get commits using git log
  Future<List<ChangelogEntry>> getCommits({
    required String projectDir,
    required String baseBranch,
  }) async {
    try {
      final gitUser = await _getCurrentGitUser(projectDir);

      // Git log command to get commits by current user
      final result = await Process.run(
        'git',
        [
          'log',
          '--pretty=format:%H|%an|%aI|%s',
          '--author=$gitUser',
          '--no-merges',
        ],
        workingDirectory: projectDir,
      );

      if (result.exitCode != 0) {
        throw Exception('Git log failed: ${result.stderr}');
      }

      final lines = (result.stdout as String)
          .split('\n')
          .where((line) => line.trim().isNotEmpty);
      final commits = <ChangelogEntry>[];

      for (final line in lines) {
        try {
          final commit = ChangelogEntry.fromGitLogLine(line.trim());
          commits.add(commit);
        } catch (e) {
          // Skip invalid lines
          continue;
        }
      }

      return commits;
    } catch (e) {
      throw Exception('Failed to get git commits: $e');
    }
  }

  /// Get current git user
  Future<String> _getCurrentGitUser(String projectDir) async {
    final result = await Process.run(
      'git',
      ['config', 'user.name'],
      workingDirectory: projectDir,
    );

    if (result.exitCode != 0) {
      throw Exception('Could not get git user: ${result.stderr}');
    }

    return (result.stdout as String).trim();
  }

  /// Check if directory is a git repository
  Future<bool> isGitRepository(String projectDir) async {
    final gitDir = Directory('$projectDir/.git');
    return gitDir.existsSync();
  }
}
