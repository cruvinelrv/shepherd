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
      final isMicrofrontends =
          await _repository.isMicrofrontendsProject(projectDir);

      if (isMicrofrontends) {
        // For microfrontends, create a unified changelog at root level
        final wasUpdated =
            await _updateUnifiedMicrofrontendsChangelog(projectDir, baseBranch);
        if (wasUpdated) {
          updatedPaths.add(projectDir);
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
  Future<bool> _updateSingleProject(
      String projectDir, String baseBranch) async {
    // Get current version
    final version = await _repository.getCurrentVersion(projectDir);

    // Get commits first to check if there are any
    final commits = await _repository.getCommits(
      projectDir: projectDir,
      baseBranch: baseBranch,
    );

    // If no commits, check version change as fallback
    if (commits.isEmpty) {
      final needsUpdate =
          await _repository.needsUpdate(projectDir, version.version);
      if (!needsUpdate) {
        print('No version change detected for $projectDir, skipping update.');
        return false;
      }
    }

    // Filter semantic commits by current user
    final semanticCommits = commits
        .where((commit) => commit.isSemanticCommit && !commit.isMergeCommit)
        .toList();

    if (semanticCommits.isEmpty) {
      print('No semantic commits found for $projectDir');
      return false;
    }

    // Check if commits are already in changelog
    final currentChangelog = await _repository.readChangelog(projectDir);
    final newCommits = _filterNewCommits(semanticCommits, currentChangelog);

    if (newCommits.isEmpty) {
      print('All commits are already in changelog for $projectDir');
      return false;
    }

    // Get current branch
    final currentBranch = await _repository.getCurrentBranch(projectDir);

    // Check if version changed
    final versionChanged =
        await _hasVersionChanged(projectDir, version.version, currentChangelog);

    String changelogContent;
    if (versionChanged && currentChangelog.isNotEmpty) {
      // If version changed, archive old changelog and create fresh one
      await _repository.archiveOldChangelog(projectDir, currentChangelog);
      changelogContent =
          _generateChangelogContent(version.version, newCommits, currentBranch);
    } else {
      // If same version, combine with existing changelog
      changelogContent = _combineWithExistingChangelog(
          version.version, newCommits, currentBranch, currentChangelog);
    }

    // Write new changelog
    await _repository.writeChangelog(projectDir, changelogContent);

    print(
        'Updated changelog for $projectDir with ${newCommits.length} commits');
    return true;
  }

  /// Generate changelog content
  String _generateChangelogContent(
      String version, List<ChangelogEntry> commits, String currentBranch) {
    final buffer = StringBuffer();
    buffer.writeln('# CHANGELOG [$version]');
    buffer.writeln();
    buffer.writeln('Branch: $currentBranch');
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
          buffer.writeln(commit.toDetailedMarkdown());
        }
        buffer.writeln();
      }
    }

    // Add any remaining types
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
        version = await _findVersionInMicrofrontends(projectDir);
      }

      // Get commits from all the repository (unified approach)
      final commits = await _repository.getCommits(
        projectDir: projectDir,
        baseBranch: baseBranch,
      );

      // If no commits, check version change as fallback
      if (commits.isEmpty) {
        final needsUpdate = await _repository.needsUpdate(projectDir, version);
        if (!needsUpdate) {
          print('No version change detected for $projectDir, skipping update.');
          return false;
        }
      }

      // Filter semantic commits by current user
      final semanticCommits =
          commits.where((commit) => commit.isSemanticCommit).toList();

      if (semanticCommits.isEmpty) {
        print('No semantic commits found for $projectDir');
        return false;
      }

      // Get current branch
      final currentBranch = await _repository.getCurrentBranch(projectDir);

      // Read existing changelog to check for version change
      final currentChangelog = await _repository.readChangelog(projectDir);
      final versionChanged =
          await _hasVersionChanged(projectDir, version, currentChangelog);

      String changelogContent;
      if (versionChanged && currentChangelog.isNotEmpty) {
        // If version changed, archive old changelog and create fresh one
        await _repository.archiveOldChangelog(projectDir, currentChangelog);
        changelogContent =
            _generateChangelogContent(version, semanticCommits, currentBranch);
      } else {
        // If same version, filter commits already in changelog
        final newCommits = _filterNewCommits(semanticCommits, currentChangelog);
        if (newCommits.isEmpty) {
          print('All commits are already in changelog for $projectDir');
          return false;
        }
        changelogContent = _combineWithExistingChangelog(
            version, newCommits, currentBranch, currentChangelog);
      }

      // Write new changelog
      await _repository.writeChangelog(projectDir, changelogContent);

      final commitCount = versionChanged
          ? semanticCommits.length
          : _filterNewCommits(semanticCommits, currentChangelog).length;
      print('Updated changelog for $projectDir with $commitCount commits');
      return true;
    } catch (e) {
      print('Error updating unified changelog for $projectDir: $e');
      return false;
    }
  }

  /// Find version by searching in microfrontends directories
  Future<String> _findVersionInMicrofrontends(String projectDir) async {
    try {
      // Get microfrontends configuration
      final microfrontends = await _repository.getMicrofrontends(projectDir);

      // Search for version in each microfrontend directory
      for (final mf in microfrontends) {
        try {
          final mfPath = '$projectDir/${mf.path}';
          final projectVersion = await _repository.getCurrentVersion(mfPath);
          return projectVersion.version;
        } catch (e) {
          // Continue to next microfrontend if this one doesn't have pubspec.yaml
          continue;
        }
      }

      // If no version found in any microfrontend, use timestamp as fallback
      final timestampVersion =
          DateTime.now().toString().substring(0, 10).replaceAll('-', '.');
      print(
          'No version found in microfrontends, using timestamp: $timestampVersion');
      return timestampVersion;
    } catch (e) {
      // If any error occurs, use timestamp as fallback
      final timestampVersion =
          DateTime.now().toString().substring(0, 10).replaceAll('-', '.');
      print(
          'Error searching microfrontends for version, using timestamp: $timestampVersion');
      return timestampVersion;
    }
  }

  /// Filter commits that are not already in the changelog
  List<ChangelogEntry> _filterNewCommits(
      List<ChangelogEntry> commits, String currentChangelog) {
    if (currentChangelog.isEmpty) {
      return commits; // If no existing changelog, all commits are new
    }

    final newCommits = <ChangelogEntry>[];

    for (final commit in commits) {
      // Check if commit hash is already in the changelog
      final shortHash =
          commit.hash.length > 8 ? commit.hash.substring(0, 8) : commit.hash;
      if (!currentChangelog.contains(shortHash)) {
        newCommits.add(commit);
      }
    }

    return newCommits;
  }

  /// Combine new commits with existing changelog
  String _combineWithExistingChangelog(
    String version,
    List<ChangelogEntry> newCommits,
    String currentBranch,
    String existingChangelog,
  ) {
    if (existingChangelog.isEmpty) {
      // If no existing changelog, create a new one
      return _generateChangelogContent(version, newCommits, currentBranch);
    }

    // Parse existing changelog and extract existing commits
    final existingCommits = _parseExistingCommits(existingChangelog);

    // Combine new and existing commits
    final allCommits = [...newCommits, ...existingCommits];

    // Generate complete changelog with combined commits
    return _generateChangelogContent(version, allCommits, currentBranch);
  }

  /// Check if version has changed compared to existing changelog
  Future<bool> _hasVersionChanged(String projectDir, String currentVersion,
      String existingChangelog) async {
    if (existingChangelog.isEmpty) {
      return false; // No existing changelog, so no version change
    }

    // Extract version from existing changelog header
    final versionPattern = RegExp(r'# CHANGELOG \[([^\]]+)\]');
    final match = versionPattern.firstMatch(existingChangelog);

    if (match == null) {
      return true; // No version header found, treat as version change
    }

    final existingVersion = match.group(1);
    return existingVersion != currentVersion;
  }

  /// Parse existing commits from changelog content
  List<ChangelogEntry> _parseExistingCommits(String changelog) {
    final commits = <ChangelogEntry>[];
    final lines = changelog.split('\n');

    for (final line in lines) {
      // Look for commit lines in format: - hash **type**: description [author, date]
      if (line.trim().startsWith('- ') &&
          line.contains('**') &&
          line.contains('[') &&
          line.contains(']')) {
        try {
          // Extract components from the line
          final trimmed = line.trim().substring(2); // Remove "- "
          final hashEnd = trimmed.indexOf(' ');
          if (hashEnd == -1) continue;

          final hash = trimmed.substring(0, hashEnd);
          final rest = trimmed.substring(hashEnd + 1);

          // Extract type and description
          final typeMatch =
              RegExp(r'\*\*(.*?)\*\*: (.+?) \[(.+?), (.+?)\]').firstMatch(rest);
          if (typeMatch == null) continue;

          final type = typeMatch.group(1) ?? '';
          final description = typeMatch.group(2) ?? '';
          final author = typeMatch.group(3) ?? '';
          final dateStr = typeMatch.group(4) ?? '';

          // Parse date
          DateTime date;
          try {
            date = DateTime.parse(dateStr);
          } catch (e) {
            date = DateTime.now();
          }

          commits.add(ChangelogEntry(
            hash: hash.padRight(40, '0'), // Pad hash to full length
            type: type,
            scope: '',
            description: description,
            author: author,
            date: date,
            isMergeCommit: false,
            isSemanticCommit: true,
          ));
        } catch (e) {
          // Skip malformed lines
          continue;
        }
      }
    }

    return commits;
  }
}
