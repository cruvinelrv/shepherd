import 'dart:io';

/// CLI interface for changelog operations
class ChangelogCli {
  /// Prompt user for base branch
  Future<String> promptBaseBranch() async {
    stdout.write(
        'Enter the base branch for the changelog (e.g., main, develop): ');
    final input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      throw Exception('Base branch not provided.');
    }

    return input;
  }

  /// Prompt user for changelog type (update or change)
  Future<String> promptChangelogType() async {
    stdout.write(
        "Is this branch for update or change? (Type 'update' or 'change'): ");
    final input = stdin.readLineSync()?.trim().toLowerCase();
    if (input == null || (input != 'update' && input != 'change')) {
      throw Exception(
          "Invalid changelog type. Please type 'update' or 'change'.");
    }
    return input;
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
  Future<void> ensureChangelogFromReference(
      {String referenceBranch = 'main'}) async {
    final result = Process.runSync(
        'git', ['checkout', referenceBranch, '--', 'CHANGELOG.md']);
    if (result.exitCode != 0) {
      print('Warning: Could not copy CHANGELOG.md from $referenceBranch.');
    } else {
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
