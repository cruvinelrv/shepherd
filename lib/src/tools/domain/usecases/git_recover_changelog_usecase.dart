import 'dart:io';
import '../entities/changelog_entities.dart';
import '../repositories/i_changelog_repository.dart';

/// Use case for recovering changelog by date (shepherd gitrecover)
class GitRecoverChangelogUseCase {
  final IChangelogRepository _repository;

  GitRecoverChangelogUseCase(this._repository);

  /// Execute changelog recovery by date range
  Future<String> execute({
    required String projectDir,
    required DateTime since,
    DateTime? until,
  }) async {
    // Format dates for git log
    final sinceStr = since.toIso8601String().substring(0, 10);
    final untilStr = until?.toIso8601String().substring(0, 10);

    // Get commits by date range using git log directly
    final args = [
      'log',
      '--pretty=format:%H|%an|%aI|%s',
      '--no-merges',
      '--since=$sinceStr',
    ];
    if (untilStr != null) {
      args.add('--until=$untilStr');
    }
    final result = await Process.run('git', args, workingDirectory: projectDir);
    if (result.exitCode != 0) {
      return '# CHANGELOG\n\nError running git log: ${result.stderr}';
    }
    final lines = (result.stdout as String).split('\n').where((line) => line.trim().isNotEmpty);
    final commits = <ChangelogEntry>[];
    for (final line in lines) {
      try {
        final commit = ChangelogEntry.fromGitLogLine(line.trim());
        if (commit.isSemanticCommit && !commit.isMergeCommit) {
          commits.add(commit);
        }
      } catch (e) {
        continue;
      }
    }
    if (commits.isEmpty) {
      return '# CHANGELOG\n\nNo commits found for the selected date range.';
    }

    // Get current branch
    final branchName = await _repository.getCurrentBranch(projectDir);
    // Use today's date as version
    final version = DateTime.now().toString().substring(0, 10).replaceAll('-', '.');

    // Generate changelog
    final buffer = StringBuffer();
    buffer.writeln('# CHANGELOG [$version]');
    buffer.writeln();
    buffer.writeln('Branch: $branchName');
    buffer.writeln();
    final groupedCommits = <String, List<ChangelogEntry>>{};
    for (final commit in commits) {
      groupedCommits.putIfAbsent(commit.type, () => []).add(commit);
    }
    final typeOrder = [
      'feat',
      'fix',
      'refactor',
      'perf',
      'test',
      'tests',
      'docs',
      'style',
      'chore',
      'ci',
      'build'
    ];
    for (final type in typeOrder) {
      final typeCommits = groupedCommits[type];
      if (typeCommits != null && typeCommits.isNotEmpty) {
        buffer.writeln('## ${_capitalizeType(type)}');
        for (final commit in typeCommits) {
          buffer.writeln(commit.toDetailedMarkdown());
        }
        buffer.writeln();
      }
    }
    for (final entry in groupedCommits.entries) {
      if (!typeOrder.contains(entry.key)) {
        buffer.writeln('## ${_capitalizeType(entry.key)}');
        for (final commit in entry.value) {
          buffer.writeln(commit.toDetailedMarkdown());
        }
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  String _capitalizeType(String type) {
    switch (type) {
      case 'feat':
        return 'Features';
      case 'fix':
        return 'Bug Fixes';
      case 'refactor':
        return 'Refactoring';
      case 'perf':
        return 'Performance';
      case 'test':
      case 'tests':
        return 'Tests';
      case 'docs':
        return 'Documentation';
      case 'style':
        return 'Style';
      case 'chore':
        return 'Chores';
      case 'ci':
        return 'CI/CD';
      case 'build':
        return 'Build';
      default:
        return type.substring(0, 1).toUpperCase() + type.substring(1);
    }
  }
}
