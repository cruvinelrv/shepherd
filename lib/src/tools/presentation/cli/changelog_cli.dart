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
}
