/// Centralized regular expressions for Shepherd CLI.
class ShepherdRegex {
  /// Regex for semantic prefixes at the absolute start of the message
  static final RegExp commitSemanticPrefix =
      RegExp(r'^[a-f0-9]+\s+(refactor:|feat:|fix:)', caseSensitive: false);

  /// Matches GitHub repo in a git remote URL (e.g., owner/repo)
  static final RegExp githubRepo = RegExp(r'[:/]([^/]+/[^/.]+?)(?:\.git)?');

  /// Validates OWNER/REPO format
  static final RegExp ownerRepo = RegExp(r'^[^/]+/[^/]+$');

  /// Matches version in pubspec.yaml (e.g., version: 1.2.3)
  static final RegExp pubspecVersion =
      RegExp(r'version:\s*([0-9]+\.[0-9]+\.[0-9]+)');

  /// Matches version in changelog header (e.g., # CHANGELOG [1.2.3])
  static final RegExp changelogHeader =
      RegExp(r'# CHANGELOG \[([0-9]+\.[0-9]+\.[0-9]+)\]');

  /// Matches branch ID (e.g., ABC-123)
  static final RegExp branchId = RegExp(r'([A-Z]+-[0-9]+)');

  /// Removes branch ID prefix from branch name
  static final RegExp branchIdPrefix = RegExp(r'^[A-Z]+-[0-9]+-?');

  /// Matches author in commit log line (e.g., [Vinicius Cruvinel, ...])
  static final RegExp commitAuthor = RegExp(r'\[(.*?),');

  /// Matches parent hashes in commit log line (after date colchete)
  static final RegExp commitParents = RegExp(r'\[.*?\]\s*(.*)$');
}
