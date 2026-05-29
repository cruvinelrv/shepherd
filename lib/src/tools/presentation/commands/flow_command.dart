import 'dart:io';
import 'package:args/args.dart';
import 'package:shepherd/src/tools/domain/services/changelog_service.dart';
import 'package:shepherd/src/tools/domain/repositories/changelog_repository.dart';
import 'package:shepherd/src/tools/data/repositories/changelog_repository.dart';
import 'package:shepherd/src/tools/data/datasources/file_changelog_datasource.dart';
import 'package:shepherd/src/tools/data/datasources/git_datasource.dart';
import 'package:shepherd/src/tools/data/datasources/pubspec_datasource.dart';

/// Runs the complete TBD release flow locally:
/// 1. Bumps the version in pubspec.yaml.
/// 2. Updates CHANGELOG.md and archives old version to dev_tools/changelog_history.md.
/// 3. Commits and pushes the changes to origin.
/// 4. Creates and pushes the version tag to remote, triggering the CD deploy pipeline.
Future<void> runFlowCommand(List<String> arguments) async {
  final parser = ArgParser();
  parser.addOption('bump', abbr: 'p', help: 'Version bump type (keep, patch, minor, major)', allowed: ['keep', 'patch', 'minor', 'major']);
  parser.addOption('base', abbr: 'b', help: 'Base tag/commit to compare against (default: auto-detected previous tag)');
  parser.addFlag('interactive', abbr: 'i', help: 'Prompt for inputs if not specified', defaultsTo: true);

  try {
    final results = parser.parse(arguments);
    final service = ChangelogService();
    final projectDir = Directory.current.path;

    // 1. Check Git status
    final branchResult = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (branchResult.exitCode != 0) {
      print('Error: Directory is not a Git repository.');
      return;
    }
    final currentBranch = (branchResult.stdout as String).trim();
    print('Current branch: $currentBranch');

    // Load repository to get current version
    final repo = ChangelogRepository(
      FileChangelogDatasource(),
      GitDatasource(),
      PubspecDatasource(FileChangelogDatasource()),
    );
    final currentVersion = await repo.getProjectVersionWithFallback(projectDir);
    if (currentVersion == null || currentVersion.isEmpty) {
      print('Error: Could not read project version from pubspec.yaml.');
      return;
    }
    print('Current version in pubspec.yaml: $currentVersion');

    // 2. Resolve version bump type
    var bumpType = results['bump'] as String?;
    if (bumpType == null && results['interactive'] == true) {
      stdout.write('Choose version bump [1: Keep ($currentVersion), 2: Patch, 3: Minor, 4: Major]: ');
      final choice = stdin.readLineSync()?.trim();
      if (choice == '2') bumpType = 'patch';
      else if (choice == '3') bumpType = 'minor';
      else if (choice == '4') bumpType = 'major';
      else bumpType = 'keep';
    } else {
      bumpType ??= 'keep';
    }

    // Determine new version
    var newVersion = currentVersion;
    if (bumpType != 'keep') {
      newVersion = _bumpVersion(currentVersion, bumpType);
      print('Bumping version to: $newVersion');

      // Update version in pubspec.yaml
      final pubspecFile = File('$projectDir/pubspec.yaml');
      if (pubspecFile.existsSync()) {
        final lines = pubspecFile.readAsLinesSync();
        final newLines = lines.map((line) {
          if (line.trim().startsWith('version:')) {
            // Preserve indentation
            final indent = line.length - line.trimLeft().length;
            return '${" " * indent}version: $newVersion';
          }
          return line;
        }).toList();
        pubspecFile.writeAsStringSync('${newLines.join('\n')}\n');
        print('pubspec.yaml updated to version $newVersion.');
      }
    }

    // 3. Resolve base branch or tag
    var base = results['base'] as String?;
    if (base == null || base.isEmpty) {
      final gitResult = await Process.run('git', ['describe', '--tags', '--abbrev=0']);
      if (gitResult.exitCode == 0) {
        base = (gitResult.stdout as String).trim();
        // If the current HEAD tag matches the new version, get the one before it
        if (base == 'v$newVersion' || base == newVersion) {
          final gitResultPrev = await Process.run('git', ['describe', '--tags', '--abbrev=0', 'HEAD^']);
          if (gitResultPrev.exitCode == 0) {
            base = (gitResultPrev.stdout as String).trim();
          }
        }
      } else {
        base = 'main';
      }
    }
    print('Comparing commits against base: $base');

    // 4. Update CHANGELOG.md & archive history
    print('Generating changelog for version $newVersion...');
    final updatedPaths = await service.updateChangelog(
      baseBranch: base,
      changelogType: 'change',
      projectDir: projectDir,
    );

    if (updatedPaths.isNotEmpty) {
      print('CHANGELOG.md updated successfully.');
      // Update header with correct version
      await service.updateChangelogHeader(newVersion);
    }

    // 5. Git Commit & Push Changes
    print('Staging changes (pubspec.yaml, CHANGELOG.md, dev_tools/changelog_history.md)...');
    await Process.run('git', ['add', 'pubspec.yaml', 'CHANGELOG.md', 'dev_tools/changelog_history.md']);

    final commitMsg = 'docs: update CHANGELOG.md and bump version to $newVersion [skip ci]';
    print('Committing: "$commitMsg"...');
    final commitResult = await Process.run('git', ['commit', '-m', commitMsg]);
    if (commitResult.exitCode != 0) {
      print('Commit skipped: No changes to commit (or already committed).');
    } else {
      print('Changes committed successfully.');
      print('Pushing commits to remote main branch...');
      final pushResult = await Process.run('git', ['push', 'origin', 'HEAD']);
      if (pushResult.exitCode != 0) {
        print('Error pushing commits: ${pushResult.stderr}');
        return;
      }
      print('Commits pushed to remote branch successfully.');
    }

    // 6. Create Git Tag and Push Tag
    final tagName = 'v$newVersion';
    print('Creating local Git tag: $tagName...');
    final tagResult = await Process.run('git', ['tag', tagName]);
    if (tagResult.exitCode != 0) {
      print('Tag creation warning (it might already exist): ${tagResult.stderr}');
    } else {
      print('Tag $tagName created locally.');
    }

    print('Pushing tag $tagName to remote origin...');
    final pushTagResult = await Process.run('git', ['push', 'origin', tagName]);
    if (pushTagResult.exitCode != 0) {
      print('Error pushing tag: ${pushTagResult.stderr}');
      return;
    }

    print('==================================================');
    print('✅ SUCCESS: Version $newVersion released!');
    print('Tag $tagName pushed to remote, triggering the CD deploy pipeline.');
    print('==================================================');

  } catch (e) {
    print('Error running release flow: $e');
    exit(1);
  }
}

String _bumpVersion(String current, String type) {
  final clean = current.split('+').first.trim();
  final parts = clean.split('.').map(int.parse).toList();
  if (parts.length < 3) {
    throw FormatException('Invalid version string in pubspec.yaml: $current');
  }

  if (type == 'patch') {
    parts[2]++;
  } else if (type == 'minor') {
    parts[1]++;
    parts[2] = 0;
  } else if (type == 'major') {
    parts[0]++;
    parts[1] = 0;
    parts[2] = 0;
  }

  // Handle build number if originally present (e.g. +1 -> +1)
  final buildParts = current.split('+');
  final buildNum = buildParts.length > 1 ? '+${buildParts.last.trim()}' : '';

  return '${parts.join('.')}$buildNum';
}
