import 'dart:io';

/// CLI interface for changelog operations
class ChangelogCli {
  /// Prompt user for base branch
  Future<String> promptBaseBranch() async {
    stdout.write('Enter the base branch for the changelog (e.g., main, develop): ');
    final input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      throw Exception('Base branch not provided.');
    }

    return input;
  }

  /// Prompt user for changelog type (update or change), with explanation, suggestion and help (English)
  Future<String> promptChangelogType({String? branchName}) async {
    String? suggestion;
    final currentBranch = branchName ?? await _getCurrentGitBranch();
    // Suggest automatically based on branch name
    if (currentBranch.startsWith('feature/') ||
        currentBranch.startsWith('fix/') ||
        currentBranch.startsWith('hotfix/')) {
      suggestion = 'change';
    } else if (currentBranch == 'main' ||
        currentBranch == 'develop' ||
        currentBranch.startsWith('release')) {
      suggestion = 'update';
    }
    while (true) {
      stdout.writeln('''\nChoose the changelog update type:\n'''
          "[update] Copy changelog from another branch (e.g., release, merging develop/main)\n"
          "[change] Generate changelog from the commits in this branch (e.g., feature, fix)\n"
          "Type '?' for examples and detailed explanation.\n");
      if (suggestion != null) {
        stdout.write(
            "Recommended for branch '$currentBranch': $suggestion. Press Enter to accept or type 'update'/'change': ");
      } else {
        stdout.write("Type 'update' or 'change': ");
      }
      final inputRaw = stdin.readLineSync();
      final input = inputRaw?.trim().toLowerCase();
      if (input == null || input.isEmpty) {
        if (suggestion != null) return suggestion;
        continue;
      }
      if (input == '?' || input == 'help') {
        stdout.writeln('''\nWhen to use each option:\n'''
            "- update: Use when you are preparing a release, merging develop/main, or need to copy the changelog from a reference branch.\n"
            "  Example: branch 'release/1.2.0', 'main', 'develop'.\n"
            "- change: Use when you are developing a feature, fix, or hotfix and want to generate the changelog from the commits made in this branch.\n"
            "  Example: branch 'feature/new-feature', 'fix/bug-x', 'hotfix/patch-y'.\n");
        continue;
      }
      if (input == 'update' || input == 'change') {
        return input;
      }
      stdout.writeln("Invalid option. Type 'update', 'change' or '?' for help.");
    }
  }

  Future<String> _getCurrentGitBranch() async {
    final result = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
    return '';
  }

  /// Show update result
  void showUpdateResult(List<String> updatedPaths) {
    if (updatedPaths.isEmpty) {
      print('No paths were updated.');
      return;
    }

    print('CHANGELOG.md successfully updated for:');
    for (final path in updatedPaths) {
      print('  - $path');
    }
  }

  /// Show error message
  void showError(String message) {
    print('Error updating changelog: $message');
  }

  /// Show info message
  void showInfo(String message) {
    print(message);
  }

  /// Ensure CHANGELOG.md is copied from the reference branch before generating changelog
  Future<void> ensureChangelogFromReference({String referenceBranch = 'main'}) async {
    final result = Process.runSync('git', ['show', '$referenceBranch:CHANGELOG.md']);
    if (result.exitCode != 0) {
      print('Warning: Could not copy CHANGELOG.md from $referenceBranch.');
    } else {
      final file = File('CHANGELOG.md');
      file.writeAsStringSync(result.stdout);
      print('CHANGELOG.md copied from $referenceBranch.');
    }
  }

  /// Update the changelog header to the chosen version
  Future<void> updateChangelogVersion(String version,
      {String changelogPath = 'CHANGELOG.md'}) async {
    final file = File(changelogPath);
    if (!await file.exists()) return;
    final lines = await file.readAsLines();
    if (lines.isNotEmpty && lines.first.startsWith('# CHANGELOG [')) {
      lines[0] = '# CHANGELOG [$version]';
      await file.writeAsString(lines.join('\n'));
    }
  }
}
