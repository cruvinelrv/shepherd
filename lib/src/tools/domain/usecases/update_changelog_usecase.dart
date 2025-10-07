import '../entities/changelog_entities.dart';
import '../repositories/i_changelog_repository.dart';

/// Use case for updating changelog
class UpdateChangelogUseCase {
  final IChangelogRepository _repository;

  UpdateChangelogUseCase(this._repository);

  /// Execute changelog update
  Future<List<String>> execute({
    required String projectDir,
    required String baseBranch,
  }) async {
    final updatedPaths = <String>[];

    try {
      final isMicrofrontends = await _repository.isMicrofrontendsProject(projectDir);

      if (isMicrofrontends) {
        final microfrontends = await _repository.getMicrofrontends(projectDir);

        // Process each microfrontend
        for (final mf in microfrontends) {
          final mfPath = '$projectDir/${mf.path}';
          final wasUpdated = await _updateSingleProject(mfPath, baseBranch);
          if (wasUpdated) {
            updatedPaths.add(mfPath);
          }
        }
      } else {
        // Process single project
        final wasUpdated = await _updateSingleProject(projectDir, baseBranch);
        if (wasUpdated) {
          updatedPaths.add(projectDir);
        }
      }

      return updatedPaths;
    } catch (e) {
      rethrow;
    }
  }

  /// Update changelog for a single project
  /// Returns true if the changelog was actually updated, false otherwise
  Future<bool> _updateSingleProject(String projectDir, String baseBranch) async {
    // Get current version
    final version = await _repository.getCurrentVersion(projectDir);

    // Check if update needed
    final needsUpdate = await _repository.needsUpdate(projectDir, version.version);
    if (!needsUpdate) {
      print('No version change detected for $projectDir, skipping update.');
      return false;
    }

    // Get commits
    final commits = await _repository.getCommits(
      projectDir: projectDir,
      baseBranch: baseBranch,
    );

    // Filter semantic commits by current user
    final semanticCommits =
        commits.where((commit) => commit.isSemanticCommit && !commit.isMergeCommit).toList();

    if (semanticCommits.isEmpty) {
      print('No semantic commits found for $projectDir');
      return false;
    }

    // Generate changelog content
    final changelogContent = _generateChangelogContent(version.version, semanticCommits);

    // Archive old changelog if version changed
    final currentChangelog = await _repository.readChangelog(projectDir);
    if (currentChangelog.isNotEmpty) {
      await _repository.archiveOldChangelog(projectDir, currentChangelog);
    }

    // Write new changelog
    await _repository.writeChangelog(projectDir, changelogContent);

    print('Updated changelog for $projectDir with ${semanticCommits.length} commits');
    return true;
  }

  /// Generate changelog content
  String _generateChangelogContent(String version, List<ChangelogEntry> commits) {
    final buffer = StringBuffer();
    buffer.writeln('# CHANGELOG [$version]');
    buffer.writeln();

    // Group commits by type
    final groupedCommits = <String, List<ChangelogEntry>>{};
    for (final commit in commits) {
      groupedCommits.putIfAbsent(commit.type, () => []).add(commit);
    }

    // Write commits by type
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

    // Add any remaining types
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
