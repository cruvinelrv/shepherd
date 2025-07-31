class FeatureToggleEntity {
  final int? id;
  final String name;
  final bool enabled;
  final String domain;
  final String description;

  const FeatureToggleEntity({
    this.id,
    required this.name,
    required this.enabled,
    required this.domain,
    required this.description,
  });
}
