import 'dart:io';

/// CLI for update prompt interaction
class UpdatePromptCli {
  /// Display update notification and prompt user for action
  /// Returns true if user wants to update, false otherwise
  bool promptForUpdate(
      String currentVersion, String latestVersion, String changelogUrl) {
    // Display notification
    _displayUpdateNotification(currentVersion, latestVersion, changelogUrl);

    // Prompt user
    stdout.write('\nUpdate now? (y/n): ');
    final input = stdin.readLineSync()?.trim().toLowerCase();

    return input == 'y' || input == 'yes';
  }

  /// Display the update notification box
  void _displayUpdateNotification(
      String currentVersion, String latestVersion, String changelogUrl) {
    final versionPadding =
        ' ' * (18 - currentVersion.length - latestVersion.length);

    print('╭──────────────────────────────────────────────────────────────╮');
    print(
        '│ 📦 Update available: $currentVersion → $latestVersion$versionPadding│');
    print('│                                                              │');
    print('│ 📋 What\'s new? $changelogUrl │');
    print('╰──────────────────────────────────────────────────────────────╯');
  }

  /// Display update in progress message
  void displayUpdating() {
    print('⏳ Updating Shepherd...');
  }

  /// Display success message
  void displaySuccess(String version) {
    print('✅ Successfully updated to $version!');
  }

  /// Display error message
  void displayError(String error, {String? manualCommand}) {
    print('❌ Update failed: $error');
    print('   You can update manually: ${manualCommand ?? 'shepherd update'}');
  }
}
