import '../entities/changelog_entities.dart';
import '../repositories/i_changelog_repository.dart';

/// Use case for updating changelog for change branches (feature, fix, etc.)
class UpdateChangelogForChangeUseCase {
  /// Update unified changelog for microfrontends project
  Future<bool> _updateUnifiedMicrofrontendsChangelog(
      String projectDir, String baseBranch) async {
    try {
      // Try to get version from root pubspec.yaml first
      String version;
      try {
        final projectVersion = await _repository.getCurrentVersion(projectDir);
        version = projectVersion.version;
      } catch (e) {
        // If no pubspec.yaml at root, search in microfrontends directories
        version = await _findVersionWithFallback(projectDir);
      }

      // Get commits from all the repository (unified approach)
      final commits = await _repository.getCommits(
        projectDir: projectDir,
        baseBranch: baseBranch,
      );

      // Filter semantic commits
      final semanticCommits = commits
          .where((commit) => commit.isSemanticCommit && !commit.isMergeCommit)
          .toList();
      if (semanticCommits.isEmpty) {
        print('No semantic commits found for $projectDir');
        return false;
      }

      // Get current branch
      final currentBranch = await _repository.getCurrentBranch(projectDir);
      final currentChangelog = await _repository.readChangelog(projectDir);
      final newCommits = _filterNewCommits(semanticCommits, currentChangelog);
      if (newCommits.isEmpty) {
        print('All commits are already in changelog for $projectDir');
        return false;
      }
      String changelogContent;
      final versionChanged = _hasVersionChanged(version, currentChangelog);
      if (versionChanged && currentChangelog.isNotEmpty) {
        await _repository.archiveOldChangelog(projectDir, currentChangelog);
        changelogContent = _generateDetailedChangelogContent(
            version, currentBranch, newCommits);
      } else {
        changelogContent = _combineWithExistingChangelog(
            version, newCommits, currentBranch, currentChangelog);
        if (currentChangelog.isNotEmpty) {
          await _repository.archiveOldChangelog(projectDir, currentChangelog);
        }
      }
      await _repository.writeChangelog(projectDir, changelogContent);
      print(
          'Updated unified changelog for $projectDir with ${newCommits.length} commits');
      return true;
    } catch (e) {
      print('Error updating unified changelog for $projectDir: $e');
      return false;
    }
  }

  /// Find version by searching in microfrontends directories or fallback to timestamp
  Future<String> _findVersionWithFallback(String projectDir) async {
    try {
      final microfrontends = await _repository.getMicrofrontends(projectDir);
      for (final mf in microfrontends) {
        try {
          final mfPath = '$projectDir/${mf.path}';
          final projectVersion = await _repository.getCurrentVersion(mfPath);
          return projectVersion.version;
        } catch (e) {
          continue;
        }
      }
      // If no version found, use timestamp
      final timestampVersion =
          DateTime.now().toString().substring(0, 10).replaceAll('-', '.');
      print(
          'No version found in microfrontends, using timestamp: $timestampVersion');
      return timestampVersion;
    } catch (e) {
      final timestampVersion =
          DateTime.now().toString().substring(0, 10).replaceAll('-', '.');
      print(
          'Error searching microfrontends for version, using timestamp: $timestampVersion');
      return timestampVersion;
    }
  }

  /// Check if version has changed compared to existing changelog
  bool _hasVersionChanged(String currentVersion, String existingChangelog) {
    if (existingChangelog.isEmpty) {
      return false;
    }
    final versionPattern = RegExp(r'# CHANGELOG \[([^\]]+)\]');
    final match = versionPattern.firstMatch(existingChangelog);
    if (match == null) {
      return true;
    }
    final existingVersion = match.group(1);
    return existingVersion != currentVersion;
  }

  /// Combine new commits with existing changelog
  String _combineWithExistingChangelog(
    String version,
    List<ChangelogEntry> newCommits,
    String branchName,
    String existingChangelog,
  ) {
    if (existingChangelog.isEmpty) {
      // If no existing changelog, create a new one
      return _generateDetailedChangelogContent(version, branchName, newCommits);
    }
    // Parse existing changelog and extract existing commits (future: implement parse if needed)
    // For now, just append new commits at the top
    final buffer = StringBuffer();
    buffer.writeln('# CHANGELOG [$version]');
    buffer.writeln();
    buffer.writeln('Branch: $branchName');
    buffer.writeln();
    // Agrupa e escreve novos commits
    final groupedCommits = <String, List<ChangelogEntry>>{};
    for (final commit in newCommits) {
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
    // Adiciona o changelog existente abaixo
    buffer.writeln(existingChangelog.trim());
    return buffer.toString();
  }

  final IChangelogRepository _repository;

  UpdateChangelogForChangeUseCase(this._repository);

  /// Execute changelog update (only if there are new commits)
  Future<List<String>> execute({
    required String projectDir,
    required String baseBranch,
  }) async {
    final updatedPaths = <String>[];

    try {
      final isMicrofrontends =
          await _repository.isMicrofrontendsProject(projectDir);
      if (isMicrofrontends) {
        // Unify changelog at root level for microfrontends
        final wasUpdated =
            await _updateUnifiedMicrofrontendsChangelog(projectDir, baseBranch);
        if (wasUpdated) {
          updatedPaths.add(projectDir);
        }
      } else {
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

  Future<bool> _updateSingleProject(
      String projectDir, String baseBranch) async {
    final version = await _repository.getCurrentVersion(projectDir);
    final needsUpdate =
        await _repository.needsUpdate(projectDir, version.version);
    if (!needsUpdate) {
      print('No version change detected for $projectDir, skipping update.');
      return false;
    }
    final commits = await _repository.getCommits(
      projectDir: projectDir,
      baseBranch: baseBranch,
    );
    final semanticCommits = commits
        .where((commit) => commit.isSemanticCommit && !commit.isMergeCommit)
        .toList();
    if (semanticCommits.isEmpty) {
      print('No semantic commits found for $projectDir');
      return false;
    }
    final branchName = await _repository.getCurrentBranch(projectDir);
    final currentChangelog = await _repository.readChangelog(projectDir);
    final newCommits = _filterNewCommits(semanticCommits, currentChangelog);
    if (newCommits.isEmpty) {
      print('All commits are already in changelog for $projectDir');
      return false;
    }
    String changelogContent;
    final versionChanged =
        _hasVersionChanged(version.version, currentChangelog);
    if (versionChanged && currentChangelog.isNotEmpty) {
      await _repository.archiveOldChangelog(projectDir, currentChangelog);
      changelogContent = _generateDetailedChangelogContent(
          version.version, branchName, newCommits);
    } else {
      changelogContent = _combineWithExistingChangelog(
          version.version, newCommits, branchName, currentChangelog);
      if (currentChangelog.isNotEmpty) {
        await _repository.archiveOldChangelog(projectDir, currentChangelog);
      }
    }
    await _repository.writeChangelog(projectDir, changelogContent);
    print(
        'Updated changelog for $projectDir with ${newCommits.length} commits');
    return true;
  }

  String _generateDetailedChangelogContent(
      String version, String branchName, List<ChangelogEntry> commits) {
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

  /// Filter commits that are not already in the changelog
  List<ChangelogEntry> _filterNewCommits(
      List<ChangelogEntry> commits, String currentChangelog) {
    if (currentChangelog.isEmpty) {
      return commits;
    }
    final newCommits = <ChangelogEntry>[];
    for (final commit in commits) {
      final shortHash =
          commit.hash.length > 8 ? commit.hash.substring(0, 8) : commit.hash;
      if (!currentChangelog.contains(shortHash)) {
        newCommits.add(commit);
      }
    }
    return newCommits;
  }
}
