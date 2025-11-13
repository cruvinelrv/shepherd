import 'dart:io';
import '../../domain/entities/changelog_entities.dart';

/// Git operations datasource
class GitDatasource {
  /// Get file content from a specific branch
  Future<String> getFileFromBranch({
    required String projectDir,
    required String branch,
    required String filePath,
  }) async {
    final result = await Process.run(
      'git',
      ['show', '$branch:$filePath'],
      workingDirectory: projectDir,
    );
    if (result.exitCode != 0) {
      throw Exception('Could not get file from branch: [${result.stderr}');
    }
    return (result.stdout as String);
  }

  /// Get commits using git log
  Future<List<ChangelogEntry>> getCommits({
    required String projectDir,
    required String baseBranch,
  }) async {
    try {
      final gitUser = await _getCurrentGitUser(projectDir);

      // Git log command to get commits by current user that are not in base branch
      final result = await Process.run(
        'git',
        [
          'log',
          '--pretty=format:%H|%an|%aI|%s',
          '--author=$gitUser',
          '--no-merges',
          'HEAD',
          '^origin/$baseBranch', // Exclude commits that are already in the base branch
        ],
        workingDirectory: projectDir,
      );

      if (result.exitCode != 0) {
        throw Exception('Git log failed: ${result.stderr}');
      }

      final lines = (result.stdout as String).split('\n').where((line) => line.trim().isNotEmpty);
      final commits = <ChangelogEntry>[];

      for (final line in lines) {
        try {
          final commit = ChangelogEntry.fromGitLogLine(line.trim());

          // Skip automatic version update commits
          if (_isAutomaticVersionCommit(commit.description)) {
            continue;
          }

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

  /// Check if commit is an automatic version update
  bool _isAutomaticVersionCommit(String message) {
    final automaticPatterns = [
      RegExp(r'^update version to \d+\.\d+\.\d+$', caseSensitive: false),
      RegExp(r'^chore: update version to \d+\.\d+\.\d+$', caseSensitive: false),
      RegExp(r'^update to version \d+\.\d+\.\d+$', caseSensitive: false),
      RegExp(r'^chore: update to version \d+\.\d+\.\d+$', caseSensitive: false),
      RegExp(r'^update shepherd version to \d+\.\d+\.\d+$', caseSensitive: false),
      RegExp(r'^chore: update shepherd version to \d+\.\d+\.\d+$', caseSensitive: false),
    ];

    return automaticPatterns.any((pattern) => pattern.hasMatch(message.trim()));
  }

  /// Get current git branch
  Future<String> getCurrentBranch(String projectDir) async {
    final result = await Process.run(
      'git',
      ['branch', '--show-current'],
      workingDirectory: projectDir,
    );

    if (result.exitCode != 0) {
      throw Exception('Could not get current branch: ${result.stderr}');
    }

    return (result.stdout as String).trim();
  }
}
