import '../entities/changelog_entities.dart';
import '../repositories/i_changelog_repository.dart';

/// Use case for updating changelog for update branches (version bump, release, etc.)
class UpdateChangelogForUpdateUseCase {
  final IChangelogRepository _repository;

  UpdateChangelogForUpdateUseCase(this._repository);

  /// Execute changelog update (always writes changelog, even with no new commits)
  Future<List<String>> execute({
    required String projectDir,
    required String baseBranch,
  }) async {
    final updatedPaths = <String>[];

    try {
      final isMicrofrontends = await _repository.isMicrofrontendsProject(projectDir);

      if (isMicrofrontends) {
        final microfrontends = await _repository.getMicrofrontends(projectDir);
        for (final mf in microfrontends) {
          final mfPath = '$projectDir/${mf.path}';
          await _updateSingleProject(mfPath, baseBranch);
          updatedPaths.add(mfPath);
        }
      } else {
        await _updateSingleProject(projectDir, baseBranch);
        updatedPaths.add(projectDir);
      }
      return updatedPaths;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _updateSingleProject(String projectDir, String baseBranch) async {
    final version = await _repository.getCurrentVersion(projectDir);
    final commits = await _repository.getCommits(
      projectDir: projectDir,
      baseBranch: baseBranch,
    );
    final semanticCommits =
        commits.where((commit) => commit.isSemanticCommit && !commit.isMergeCommit).toList();
    final changelogContent = _generateChangelogContent(version.version, semanticCommits);
    final currentChangelog = await _repository.readChangelog(projectDir);
    if (currentChangelog.isNotEmpty) {
      await _repository.archiveOldChangelog(projectDir, currentChangelog);
    }
    await _repository.writeChangelog(projectDir, changelogContent);
    print('Updated changelog for $projectDir (update branch, always written)');
  }

  String _generateChangelogContent(String version, List<ChangelogEntry> commits) {
    final buffer = StringBuffer();
    buffer.writeln('# CHANGELOG [$version]');
    buffer.writeln();
    if (commits.isEmpty) {
      buffer.writeln(
          'No new commits. This changelog was generated for an update branch (e.g., version bump, release).');
      return buffer.toString();
    }
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
          buffer.writeln(commit.toMarkdown());
        }
        buffer.writeln();
      }
    }
    for (final entry in groupedCommits.entries) {
      if (!typeOrder.contains(entry.key)) {
        buffer.writeln('## ${_capitalizeType(entry.key)}');
        for (final commit in entry.value) {
          buffer.writeln(commit.toMarkdown());
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
