/// Represents the health status of a domain in the project.
/// Stores metrics such as score, commit count, days since last tag, warnings, and owners.
class DomainHealthEntity {
  final String domainName;
  final double healthScore;
  final int commitsSinceLastTag;
  final int daysSinceLastTag;
  final List<String> warnings;
  final List<String> ownerCodes;

  /// Creates a new [DomainHealthEntity] with the given properties.
  DomainHealthEntity({
    required this.domainName,
    required this.healthScore,
    required this.commitsSinceLastTag,
    required this.daysSinceLastTag,
    this.warnings = const [],
    this.ownerCodes = const [],
  });

  /// Returns a string representation of the domain health for debugging and logging.
  @override
  String toString() {
    return 'Domain: $domainName, Score: ${healthScore.toStringAsFixed(2)}, '
        'Commits: $commitsSinceLastTag, Days: $daysSinceLastTag, '
        'Warnings: ${warnings.join(', ')}';
  }

  /// Converts the domain health entity to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'domainName': domainName,
      'healthScore': healthScore,
      'commitsSinceLastTag': commitsSinceLastTag,
      'daysSinceLastTag': daysSinceLastTag,
      'warnings': warnings,
      'ownerCodes': ownerCodes,
    };
  }
}
