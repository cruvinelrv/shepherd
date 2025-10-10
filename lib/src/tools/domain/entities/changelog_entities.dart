/// Represents a changelog entry with commit information
class ChangelogEntry {
  final String hash;
  final String type;
  final String scope;
  final String description;
  final String author;
  final DateTime date;
  final bool isMergeCommit;
  final bool isSemanticCommit;

  const ChangelogEntry({
    required this.hash,
    required this.type,
    required this.scope,
    required this.description,
    required this.author,
    required this.date,
    required this.isMergeCommit,
    required this.isSemanticCommit,
  });

  /// Create from git log line
  factory ChangelogEntry.fromGitLogLine(String line) {
    // Parse git log format: hash|author|date|message
    final parts = line.split('|');
    if (parts.length < 4) {
      throw ArgumentError('Invalid git log format: $line');
    }

    final hash = parts[0];
    final author = parts[1];
    final dateStr = parts[2];
    final message = parts[3];

    final date = DateTime.parse(dateStr);
    final isMergeCommit = message.toLowerCase().contains('merge');

    // Parse semantic commit
    final semanticMatch = RegExp(
            r'^(feat|fix|refactor|tests?|docs?|style|chore|perf|ci|build|revert)(\([^)]+\))?: (.+)$')
        .firstMatch(message);

    final isSemanticCommit = semanticMatch != null;
    final type = isSemanticCommit ? semanticMatch.group(1)! : '';
    final scope =
        isSemanticCommit ? (semanticMatch.group(2) ?? '').replaceAll(RegExp(r'[()]'), '') : '';
    final description = isSemanticCommit ? semanticMatch.group(3)! : message;

    return ChangelogEntry(
      hash: hash,
      type: type,
      scope: scope,
      description: description,
      author: author,
      date: date,
      isMergeCommit: isMergeCommit,
      isSemanticCommit: isSemanticCommit,
    );
  }

  /// Convert to markdown format
  String toMarkdown() {
    if (scope.isNotEmpty) {
      return '- **$type($scope)**: $description';
    } else if (type.isNotEmpty) {
      return '- **$type**: $description';
    } else {
      return '- $description';
    }
  }

  /// Convert to detailed markdown format with hash, author and date
  String toDetailedMarkdown() {
    final shortHash = hash.length > 8 ? hash.substring(0, 8) : hash;
    final dateFormatted =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (scope.isNotEmpty) {
      return '- $shortHash **$type($scope)**: $description [$author, $dateFormatted]';
    } else if (type.isNotEmpty) {
      return '- $shortHash **$type**: $description [$author, $dateFormatted]';
    } else {
      return '- $shortHash $description [$author, $dateFormatted]';
    }
  }

  @override
  String toString() => 'ChangelogEntry($hash, $type, $description)';
}

/// Represents project version information
class ProjectVersion {
  final String version;
  final String source; // 'pubspec.yaml' or other source

  const ProjectVersion({
    required this.version,
    required this.source,
  });

  @override
  String toString() => 'ProjectVersion($version from $source)';
}

/// Represents a microfrontend configuration
class MicrofrontendConfig {
  final String name;
  final String path;
  final Map<String, dynamic> config;

  const MicrofrontendConfig({
    required this.name,
    required this.path,
    required this.config,
  });

  @override
  String toString() => 'MicrofrontendConfig($name at $path)';
}
