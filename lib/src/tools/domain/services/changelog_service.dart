import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/utils/shepherd_regex.dart';

class ChangelogService {
  /// Updates the project's CHANGELOG.md, archiving old versions and adding an entry for the current branch.
  /// [projectDir] is the project root directory. If not provided, uses the current directory.
  /// Returns true if a new entry was added, false if it already existed.
  /// Returns true if a new entry was added, false if it already existed, and null if branch is an environment branch.
  Future<List<String>> updateChangelog(
      {String? projectDir, List<String>? environments}) async {
    final dir = projectDir ?? Directory.current.path;
    final updated = <String>[];
    // Atualiza changelog da raiz, se existir pubspec.yaml
    final rootPubspec = File('$dir/pubspec.yaml');
    if (rootPubspec.existsSync()) {
      final ok = await _updateChangelogFor(dir, dir);
      if (ok) updated.add(dir);
    }
    // Busca microfrontends
    final microfrontendsFile =
        File('$dir/dev_tools/shepherd/microfrontends.yaml');
    if (microfrontendsFile.existsSync()) {
      final doc = loadYaml(microfrontendsFile.readAsStringSync());
      if (doc is YamlMap && doc['microfrontends'] is YamlList) {
        final list = List<Map>.from(
            (doc['microfrontends'] as YamlList).map((e) => Map.from(e)));
        for (final micro in list) {
          final path = micro['path']?.toString();
          if (path != null && path.isNotEmpty) {
            final mfDir = '$dir/$path';
            final mfPubspec = File('$mfDir/pubspec.yaml');
            if (mfPubspec.existsSync()) {
              final ok = await _updateChangelogFor(mfDir, dir);
              if (ok) updated.add(mfDir);
            }
          }
        }
      }
    }
    return updated;
  }

  Future<bool> _updateChangelogFor(String mfDir, String rootDir) async {
    final changelogFile = File('$mfDir/CHANGELOG.md');
    final historyFile = File('$rootDir/dev_tools/changelog_history.md');
    final pubspecFile = File('$mfDir/pubspec.yaml');
    // ...código original de updateChangelog adaptado para mfDir/pubspecFile/changelogFile...
    final pubspecContent = await pubspecFile.readAsString();
    final versionMatch =
        ShepherdRegex.pubspecVersion.firstMatch(pubspecContent);
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
        // Adiciona contexto do microfrontend ou root
        String contextName = mfDir == rootDir ? 'root' : mfDir.split('/').last;
        String versionInfo = pubspecVersion;
        historyLines.insert(1, '### [${contextName}] version: $versionInfo');
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
      final result =
          await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
      if (result.exitCode == 0) {
        branch = result.stdout.toString().trim();
      }
    } catch (_) {}
    Map<String, String> envMap = {};
    try {
      final envFile = File('$rootDir/dev_tools/shepherd/environments.yaml');
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
    final branchId = ShepherdRegex.branchId.firstMatch(branch)?.group(1) ??
        'DOMAINNAME-XXXX';
    final branchDesc = branch.replaceFirst(ShepherdRegex.branchIdPrefix, '');
    final entry =
        '- $branchId: ${branchDesc.isNotEmpty ? branchDesc : '(add a description)'} [$pubspecVersion]';
    bool alreadyExists = lines.any((l) => l.trim() == entry.trim());
    if (!alreadyExists) {
      lines.insert(dateIndex + 1, entry);
      await changelogFile.writeAsString(lines.join('\n'));
      return true;
    } else {
      return false;
    }
  }
}
