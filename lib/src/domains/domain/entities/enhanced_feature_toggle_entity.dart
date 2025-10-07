class EnhancedFeatureToggleEntity {
  final int? id;
  final String name;
  final bool enabled;
  final String domain;
  final String description;

  // Campos adicionais baseados no DynamoDB
  final String? activity;
  final String? prototype;
  final String? team;
  final List<String> ignoreDocs;
  final List<String> ignoreBundleNames;
  final List<String> blockBundleNames;
  final String? minVersion;
  final String? maxVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EnhancedFeatureToggleEntity({
    this.id,
    required this.name,
    required this.enabled,
    required this.domain,
    required this.description,
    this.activity,
    this.prototype,
    this.team,
    this.ignoreDocs = const [],
    this.ignoreBundleNames = const [],
    this.blockBundleNames = const [],
    this.minVersion,
    this.maxVersion,
    this.createdAt,
    this.updatedAt,
  });

  /// Converte para Map para persistência no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled ? 1 : 0,
      'domain': domain,
      'description': description,
      'activity': activity,
      'prototype': prototype,
      'team': team,
      'ignore_docs': ignoreDocs.join(','),
      'ignore_bundle_names': ignoreBundleNames.join(','),
      'block_bundle_names': blockBundleNames.join(','),
      'min_version': minVersion,
      'max_version': maxVersion,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Cria uma instância do Map do banco
  factory EnhancedFeatureToggleEntity.fromMap(Map<String, dynamic> map) {
    return EnhancedFeatureToggleEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      enabled: (map['enabled'] as int) == 1,
      domain: map['domain'] as String,
      description: map['description'] as String? ?? '',
      activity: map['activity'] as String?,
      prototype: map['prototype'] as String?,
      team: map['team'] as String?,
      ignoreDocs:
          (map['ignore_docs'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      ignoreBundleNames:
          (map['ignore_bundle_names'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ??
              [],
      blockBundleNames:
          (map['block_bundle_names'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ??
              [],
      minVersion: map['min_version'] as String?,
      maxVersion: map['max_version'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }

  /// Converte para YAML para exportação
  Map<String, dynamic> toYaml() {
    final yaml = <String, dynamic>{
      'name': name,
      'enabled': enabled,
      'domain': domain,
      'description': description,
    };

    if (activity != null && activity!.isNotEmpty) yaml['activity'] = activity;
    if (prototype != null && prototype!.isNotEmpty) yaml['prototype'] = prototype;
    if (team != null && team!.isNotEmpty) yaml['team'] = team;
    if (ignoreDocs.isNotEmpty) yaml['ignoreDocs'] = ignoreDocs;
    if (ignoreBundleNames.isNotEmpty) yaml['ignoreBundleNames'] = ignoreBundleNames;
    if (blockBundleNames.isNotEmpty) yaml['blockBundleNames'] = blockBundleNames;
    if (minVersion != null && minVersion!.isNotEmpty) yaml['minVersion'] = minVersion;
    if (maxVersion != null && maxVersion!.isNotEmpty) yaml['maxVersion'] = maxVersion;

    return yaml;
  }

  /// Cria uma cópia com alterações
  EnhancedFeatureToggleEntity copyWith({
    int? id,
    String? name,
    bool? enabled,
    String? domain,
    String? description,
    String? activity,
    String? prototype,
    String? team,
    List<String>? ignoreDocs,
    List<String>? ignoreBundleNames,
    List<String>? blockBundleNames,
    String? minVersion,
    String? maxVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnhancedFeatureToggleEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      domain: domain ?? this.domain,
      description: description ?? this.description,
      activity: activity ?? this.activity,
      prototype: prototype ?? this.prototype,
      team: team ?? this.team,
      ignoreDocs: ignoreDocs ?? this.ignoreDocs,
      ignoreBundleNames: ignoreBundleNames ?? this.ignoreBundleNames,
      blockBundleNames: blockBundleNames ?? this.blockBundleNames,
      minVersion: minVersion ?? this.minVersion,
      maxVersion: maxVersion ?? this.maxVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'EnhancedFeatureToggleEntity(id: $id, name: $name, enabled: $enabled, domain: $domain, team: $team)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnhancedFeatureToggleEntity && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
