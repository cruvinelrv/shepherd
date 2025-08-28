import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/utils/shepherd_regex.dart';

class ChangelogService {
  /// Updates the project's CHANGELOG.md, archiving old versions and adding an entry for the current branch.
  /// [projectDir] is the project root directory. If not provided, uses the current directory.
  /// Returns true if a new entry was added, false if it already existed.
  /// Returns true if a new entry was added, false if it already existed, and null if branch is an environment branch.
  /// Updates the root CHANGELOG.md using the version from the given microfrontend (or root) pubspec.yaml.
  /// If [projectDir] points to a microfrontend, its pubspec.yaml will be used for the version.
  /// The root CHANGELOG.md will always be updated, even if there is no pubspec.yaml in the root.
  Future<List<String>> updateChangelog({String? projectDir, List<String>? environments}) async {
    final dir = Directory.current.path;
    final updated = <String>[];
    // 1. If projectDir is provided, it has priority
    if (projectDir != null) {
      final mfPubspec = File('$projectDir/pubspec.yaml');
      if (mfPubspec.existsSync()) {
        final ok = await _updateChangelogFor(projectDir, dir);
        if (ok) updated.add(projectDir);
        return updated;
      }
    }
    // 2. Prioritize root pubspec.yaml
    final rootPubspec = File('$dir/pubspec.yaml');
    if (rootPubspec.existsSync()) {
      final ok = await _updateChangelogFor(dir, dir);
      if (ok) updated.add(dir);
      return updated;
    }
    // 3. If there is no pubspec.yaml in the root, try microfrontends.yaml
    final microfrontendsFile = File('$dir/.shepherd/microfrontends.yaml');
    if (microfrontendsFile.existsSync()) {
      final yaml = loadYaml(microfrontendsFile.readAsStringSync());
      if (yaml is Map && yaml['microfrontends'] is YamlList && yaml['microfrontends'].isNotEmpty) {
        final m = yaml['microfrontends'].first;
        final path = m['path']?.toString();
        if (path != null && path.isNotEmpty) {
          final mfPubspec = File('$dir/$path/pubspec.yaml');
          if (mfPubspec.existsSync()) {
            final ok = await _updateChangelogFor('$dir/$path', dir);
            if (ok) updated.add('$dir/$path');
            return updated;
          }
        }
      }
    }
    // 4. Fallback: example/
    if (updated.isEmpty) {
      final examplePubspec = File('$dir/example/pubspec.yaml');
      if (examplePubspec.existsSync()) {
        final ok = await _updateChangelogFor('$dir/example', dir);
        if (ok) updated.add('$dir/example');
      }
    }
    return updated;
  }

  Future<bool> _updateChangelogFor(String pubspecDir, String rootDir) async {
    final changelogFile = File('$rootDir/CHANGELOG.md');
    final historyFile = File('$rootDir/dev_tools/changelog_history.md');
    final pubspecFile = File('$pubspecDir/pubspec.yaml');
    final pubspecContent = await pubspecFile.readAsString();
    final versionMatch = ShepherdRegex.pubspecVersion.firstMatch(pubspecContent);
    if (versionMatch == null) {
      throw Exception('Version not found in pubspec.yaml');
    }
    final pubspecVersion = versionMatch.group(1)!;
    String changelog = await changelogFile.exists() ? await changelogFile.readAsString() : '';
    final lines = changelog.split('\n');
    if (lines.isEmpty || !lines.first.startsWith('# CHANGELOG')) {
      lines.insert(0, '# CHANGELOG [$pubspecVersion]');
    } else {
      lines[0] = '# CHANGELOG [$pubspecVersion]';
    }
    if (lines.length < 2 || lines[1].trim().isNotEmpty) {
      lines.insert(1, '');
    }
    final oldVersionMatch = ShepherdRegex.changelogHeader.firstMatch(changelog);
    final oldVersion = oldVersionMatch?.group(1);
    if (oldVersion != null && oldVersion != pubspecVersion) {
      final toArchive = lines.skip(1).join('\n').trim();
      if (toArchive.isNotEmpty) {
        final historyContent =
            await historyFile.exists() ? await historyFile.readAsString() : '# CHANGELOG HISTORY';
        final historyLines = historyContent.split('\n');
        if (historyLines.isEmpty || !historyLines.first.startsWith('# CHANGELOG HISTORY')) {
          historyLines.insert(0, '# CHANGELOG HISTORY');
        }
        // Adds context of the microfrontend or root
        String contextName = pubspecDir == rootDir ? 'root' : pubspecDir.split('/').last;
        String versionInfo = pubspecVersion;
        historyLines.insert(1, '### [$contextName] version: $versionInfo');
        historyLines.insert(2, toArchive);
        await historyFile.writeAsString(historyLines.join('\n'));
      }
      lines.removeRange(1, lines.length);
      lines.insert(1, '');
    }
    final now = DateTime.now();
    final today =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    final dateHeader = '## [$today]';
    int dateIndex = lines.indexWhere((l) => l.trim() == dateHeader);
    if (dateIndex == -1) {
      lines.insert(2, dateHeader);
      dateIndex = 2;
    }
    String branch = 'DOMAINNAME-XXXX-Example-description';
    try {
      final result = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
      if (result.exitCode == 0) {
        branch = result.stdout.toString().trim();
      }
    } catch (_) {}
    Map<String, String> envMap = {};
    try {
      final envFile = File('$rootDir/.shepherd/environments.yaml');
      if (envFile.existsSync()) {
        final content = envFile.readAsStringSync();
        final map = loadYaml(content);
        if (map is Map) {
          envMap = Map<String, String>.from(map);
        }
      }
    } catch (_) {}
    bool isEnvBranch = false;
    for (final pattern in envMap.values) {
      if (pattern.endsWith('*')) {
        final prefix = pattern.substring(0, pattern.length - 1);
        if (branch.startsWith(prefix)) {
          isEnvBranch = true;
          break;
        }
      } else {
        if (branch == pattern) {
          isEnvBranch = true;
          break;
        }
      }
    }
    if (isEnvBranch) {
      return false;
    }
    final branchId = ShepherdRegex.branchId.firstMatch(branch)?.group(1) ?? 'DOMAINNAME-XXXX';
    final branchDesc = branch.replaceFirst(ShepherdRegex.branchIdPrefix, '');
    // Gets commits from the branch
    // Lists only commits exclusive to the branch (not present in main)
    final gitResult = await Process.run(
      'git',
      ['log', 'main..$branch', '--pretty=format:%h %s [%an, %ad] %p', '--date=short'],
      workingDirectory: rootDir,
    );
    var commits = gitResult.stdout.toString().trim().isNotEmpty
        ? gitResult.stdout.toString().trim().split('\n')
        : [];
    // Get current user name from git config
    String currentUser = '';
    try {
      final userResult = await Process.run('git', ['config', 'user.name']);
      if (userResult.exitCode == 0) {
        currentUser = userResult.stdout.toString().trim();
      }
    } catch (_) {}
    // Filter: only commits authored by current user, exclude merges (by parent count) and unwanted types
    commits = commits.where((c) {
      final parts = c.split(' ');
      // parent hashes always come after the commit info, so get last elements
      final parentHashes = parts.length > 5 ? parts.sublist(5) : [];
      final isMerge = parentHashes.length > 1;
      return c.contains('[$currentUser,') && // authored by current user
          !isMerge &&
          !c.contains('docs:') &&
          !c.contains('chore:') &&
          !c.contains('style:');
    }).toList();
    // Inverte a ordem para top down (mais novo primeiro)
    commits = commits.reversed.toList();
    final entry =
        '- $branchId: ${branchDesc.isNotEmpty ? branchDesc : '(add a description)'} [$pubspecVersion]';
    bool alreadyExists = lines.any((l) => l.trim() == entry.trim());
    if (!alreadyExists) {
      lines.insert(dateIndex + 1, entry);
      if (commits.isNotEmpty) {
        lines.insert(dateIndex + 2, '  - Commits:');
        for (final commit in commits) {
          lines.insert(dateIndex + 3, '    - $commit');
        }
      }
      await changelogFile.writeAsString(lines.join('\n'));
      return true;
    } else {
      return false;
    }
  }
}
