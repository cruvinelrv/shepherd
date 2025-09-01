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
  Future<List<String>> updateChangelog({
    String? baseBranch,
    String? projectDir,
    List<String>? environments,
  }) async {
    final dir = Directory.current.path;
    // First verification: environment branch
    final isEnvBranch = await validateEnvironmentBranch(dir);
    if (isEnvBranch) {
      print(
          'CHANGELOG.md was NOT updated: current branch is an environment branch.');
      return [];
    }
    // Solicita baseBranch se não fornecido
    final branch = baseBranch ?? await _promptBaseBranch();
    return await _updateChangelogCommon(dir, branch);
  }

  Future<List<String>> _updateChangelogCommon(
      String dir, String baseBranch) async {
    final microfrontendsFile = File('$dir/.shepherd/microfrontends.yaml');
    if (microfrontendsFile.existsSync()) {
      return await updateChangelogMicrofrontends(dir, baseBranch);
    } else {
      return await updateChangelogSimple(dir, baseBranch);
    }
  }

  Future<String> _promptBaseBranch() async {
    stdout.write(
        'Enter the base branch for the changelog (e.g., main, develop): ');
    var baseBranch = stdin.readLineSync();
    if (baseBranch == null || baseBranch.trim().isEmpty) {
      throw Exception('Base branch not provided.');
    }
    return baseBranch.trim();
  }

  /// Updates changelog for simple projects (without microfrontends)
  Future<List<String>> updateChangelogSimple(
      String dir, String baseBranch) async {
    final updated = <String>[];
    final rootPubspec = File('$dir/pubspec.yaml');
    if (rootPubspec.existsSync()) {
      final ok = await _updateChangelogFor(dir, dir, baseBranch);
      if (ok == true) updated.add(dir);
      return updated;
    }
    // Fallback: example/
    final examplePubspec = File('$dir/example/pubspec.yaml');
    if (examplePubspec.existsSync()) {
      final ok = await _updateChangelogFor('$dir/example', dir, baseBranch);
      if (ok == true) updated.add('$dir/example');
    }
    return updated;
  }

  /// Updates changelog for projects with microfrontends enabled
  Future<List<String>> updateChangelogMicrofrontends(
      String dir, String baseBranch) async {
    final updated = <String>[];
    final microfrontendsFile = File('$dir/.shepherd/microfrontends.yaml');
    final yaml = loadYaml(microfrontendsFile.readAsStringSync());
    if (yaml is Map &&
        yaml['microfrontends'] is YamlList &&
        yaml['microfrontends'].isNotEmpty) {
      for (final m in yaml['microfrontends']) {
        final path = m['path']?.toString();
        if (path != null && path.isNotEmpty) {
          final mfPubspec = File('$dir/$path/pubspec.yaml');
          if (mfPubspec.existsSync()) {
            final ok = await _updateChangelogFor('$dir/$path', dir, baseBranch);
            if (ok == true) updated.add('$dir/$path');
          }
        }
      }
      return updated;
    }
    return [];
  }
}

/// Checks if the current branch is an environment branch defined in environments.yaml
Future<bool> validateEnvironmentBranch(String rootDir) async {
  String branch = '';
  try {
    final result =
        await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (result.exitCode == 0) {
      branch = result.stdout.toString().trim();
    }
  } catch (_) {}
  final envFile = File('$rootDir/.shepherd/environments.yaml');
  final envBranches = <String>[];
  if (envFile.existsSync()) {
    final content = envFile.readAsStringSync();
    final map = loadYaml(content);
    if (map is Map) {
      envBranches.addAll(map.values.map((v) => v.toString()));
    }
  }
  return envBranches.contains(branch);
}

Future<bool> _updateChangelogFor(
    String pubspecDir, String rootDir, String baseBranch) async {
  // Get current branch name at the start
  String branch = '';
  try {
    final result =
        await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (result.exitCode == 0) {
      branch = result.stdout.toString().trim();
    }
  } catch (_) {}
  // Load environment branches from environments.yaml
  final envFile = File('$rootDir/.shepherd/environments.yaml');
  final envBranches = <String>[];
  if (envFile.existsSync()) {
    final content = envFile.readAsStringSync();
    final map = loadYaml(content);
    if (map is Map) {
      envBranches.addAll(map.values.map((v) => v.toString()));
    }
  }
  // Block changelog update if current branch is an environment branch
  if (envBranches.contains(branch)) {
    print(
        'CHANGELOG.md was NOT updated: current branch "$branch" is an environment branch.');
    return false;
  }
  final changelogFile = File('$rootDir/CHANGELOG.md');
  final historyFile = File('$rootDir/dev_tools/changelog_history.md');
  final pubspecFile = File('$pubspecDir/pubspec.yaml');
  final pubspecContent = await pubspecFile.readAsString();
  final versionMatch = ShepherdRegex.pubspecVersion.firstMatch(pubspecContent);
  if (versionMatch == null) {
    throw Exception('Version not found in pubspec.yaml');
  }
  final pubspecVersion = versionMatch.group(1)!;
  String changelog =
      await changelogFile.exists() ? await changelogFile.readAsString() : '';
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
      final historyContent = await historyFile.exists()
          ? await historyFile.readAsString()
          : '# CHANGELOG HISTORY';
      final historyLines = historyContent.split('\n');
      if (historyLines.isEmpty ||
          !historyLines.first.startsWith('# CHANGELOG HISTORY')) {
        historyLines.insert(0, '# CHANGELOG HISTORY');
      }
      // Adds context of the microfrontend or root
      String contextName =
          pubspecDir == rootDir ? 'root' : pubspecDir.split('/').last;
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
  try {
    final result =
        await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (result.exitCode == 0) {
      branch = result.stdout.toString().trim();
    }
  } catch (_) {}
  // (Removed: duplicate environment branch validation)
  // Gets all commits from the current branch
  // Runs the git log + grep command exactly as in the terminal
  String userName = '';
  try {
    final userResult = await Process.run('git', ['config', 'user.name']);
    if (userResult.exitCode == 0) {
      userName = userResult.stdout.toString().trim();
    }
  } catch (_) {}
  String commitsOutput = '';
  try {
    final result = await Process.run(
      'bash',
      [
        '-c',
        "git log --no-merges --pretty=format:'%h %s [%an, %ad]' --date=short --author='$userName' \$(git merge-base HEAD $baseBranch)..HEAD | grep -E '^[a-f0-9]+ (refactor:|feat:|fix:)' -i"
      ],
      workingDirectory: rootDir,
    );
    // Only show the final extracted commits message
    if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
      commitsOutput = result.stdout.toString().trim();
    }
  } catch (e) {
    print('[DEBUG] Exception while running git command: $e');
  }
  if (commitsOutput.isNotEmpty) {
    final now = DateTime.now();
    final today =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    final dateHeader = '## [$today]';
    int dateIndex = lines.indexWhere((l) => l.trim() == dateHeader);
    if (dateIndex == -1) {
      lines.insert(2, dateHeader);
      dateIndex = 2;
    }
    // Insert branch name after date header if not already present
    final branchLine = 'Branch: $branch';
    if (lines.length <= dateIndex + 1 || lines[dateIndex + 1] != branchLine) {
      lines.insert(dateIndex + 1, branchLine);
    }
    final commits = commitsOutput.split('\n');
    final existingEntries = lines.skip(dateIndex + 1).toSet();
    int added = 0;
    for (final commit in commits) {
      final formattedCommit = '- $commit';
      if (!existingEntries.contains(formattedCommit)) {
        lines.insert(dateIndex + 2, formattedCommit);
        added++;
      }
    }
    if (added > 0) {
      await changelogFile.writeAsString(lines.join('\n'));
      return true;
    }
  }
  // Guarantee non-nullable return
  return false;
}
