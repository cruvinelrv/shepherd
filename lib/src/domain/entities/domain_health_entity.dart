class DomainHealthEntity {
  final String domainName;
  final double healthScore;
  final int commitsSinceLastTag;
  final int daysSinceLastTag;
  final List<String> warnings;
  final List<String> ownerCodes;

  DomainHealthEntity({
    required this.domainName,
    required this.healthScore,
    required this.commitsSinceLastTag,
    required this.daysSinceLastTag,
    this.warnings = const [],
    this.ownerCodes = const [],
  });

  @override
  String toString() {
    return 'Domain: $domainName, Score: ${healthScore.toStringAsFixed(2)}, '
        'Commits: $commitsSinceLastTag, Days: $daysSinceLastTag, '
        'Warnings: ${warnings.join(', ')}';
  }

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
