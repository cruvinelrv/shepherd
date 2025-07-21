import 'dart:io';
import 'package:shepherd/src/utils/shepherd_regex.dart';

class ChangelogService {
  /// Updates the project's CHANGELOG.md, archiving old versions and adding an entry for the current branch.
  /// [projectDir] is the project root directory. If not provided, uses the current directory.
  Future<void> updateChangelog({String? projectDir}) async {
    final dir = projectDir ?? Directory.current.path;
    final changelogFile = File('$dir/CHANGELOG.md');
    final pubspecFile = File('$dir/pubspec.yaml');
    final historyFile = File('$dir/dev_tools/changelog_history.md');

    // Get version from pubspec.yaml
    final pubspecContent = await pubspecFile.readAsString();
    final versionMatch =
        ShepherdRegex.pubspecVersion.firstMatch(pubspecContent);
    if (versionMatch == null) {
      throw Exception('Version not found in pubspec.yaml');
    }
    final pubspecVersion = versionMatch.group(1)!;

    // Read changelog
    String changelog =
        await changelogFile.exists() ? await changelogFile.readAsString() : '';
    final lines = changelog.split('\n');

    // Update header
    if (lines.isEmpty || !lines.first.startsWith('# CHANGELOG')) {
      lines.insert(0, '# CHANGELOG [$pubspecVersion]');
    } else {
      lines[0] = '# CHANGELOG [$pubspecVersion]';
    }

    // Ensure blank line after header
    if (lines.length < 2 || lines[1].trim().isNotEmpty) {
      lines.insert(1, '');
    }

    // Detect previous version
    final oldVersionMatch = ShepherdRegex.changelogHeader.firstMatch(changelog);
    final oldVersion = oldVersionMatch?.group(1);
    if (oldVersion != null && oldVersion != pubspecVersion) {
      // Move everything except the header to the history
      final toArchive = lines.skip(1).join('\n').trim();
      if (toArchive.isNotEmpty) {
        final historyContent = await historyFile.exists()
            ? await historyFile.readAsString()
            : '# CHANGELOG HISTORY';
        final historyLines = historyContent.split('\n');
        // Ensure unique header
        if (historyLines.isEmpty ||
            !historyLines.first.startsWith('# CHANGELOG HISTORY')) {
          historyLines.insert(0, '# CHANGELOG HISTORY');
        }
        // Add at the beginning of the history
        historyLines.insert(1, toArchive);
        await historyFile.writeAsString(historyLines.join('\n'));
      }
      // Clean changelog, keeping only the header
      lines.removeRange(1, lines.length);
      lines.insert(1, '');
    }

    // Today's date
    final now = DateTime.now();
    final today =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    final dateHeader = '## [$today]';
    int dateIndex = lines.indexWhere((l) => l.trim() == dateHeader);
    if (dateIndex == -1) {
      lines.insert(2, dateHeader);
      dateIndex = 2;
    }

    // Detect current git branch
    String branch = 'DOMAINNAME-XXXX-Example-description';
    try {
      final result =
          await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
      if (result.exitCode == 0) {
        branch = result.stdout.toString().trim();
      }
    } catch (_) {}
    final branchId = ShepherdRegex.branchId.firstMatch(branch)?.group(1) ??
        'DOMAINNAME-XXXX';
    final branchDesc = branch.replaceFirst(ShepherdRegex.branchIdPrefix, '');
    final entry =
        '- $branchId: ${branchDesc.isNotEmpty ? branchDesc : '(add a description)'} [$pubspecVersion]';

    // Avoid duplicates
    if (!lines.any((l) => l.contains(branchId) && l.contains(pubspecVersion))) {
      lines.insert(dateIndex + 1, entry);
      await changelogFile.writeAsString(lines.join('\n'));
    }
  }
}
