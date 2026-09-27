class AiProviderConfigEntity {
  final String id;
  final String? apiKey;
  final String? baseUrl;
  final String defaultModel;
  final List<String> knownModels;

  const AiProviderConfigEntity({
    required this.id,
    this.apiKey,
    this.baseUrl,
    required this.defaultModel,
    this.knownModels = const [],
  });

  AiProviderConfigEntity copyWith({
    String? id,
    String? apiKey,
    String? baseUrl,
    String? defaultModel,
    List<String>? knownModels,
  }) {
    return AiProviderConfigEntity(
      id: id ?? this.id,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      defaultModel: defaultModel ?? this.defaultModel,
      knownModels: knownModels ?? this.knownModels,
    );
  }
}

class AiConfigEntity {
  final String activeProvider;
  final String activeModel;
  final Map<String, AiProviderConfigEntity> providers;

  const AiConfigEntity({
    required this.activeProvider,
    required this.activeModel,
    this.providers = const {},
  });

  // Getters para compatibilidade retroativa
  String get provider => activeProvider;
  String get model => activeModel;
  String get apiKey => providers[activeProvider]?.apiKey ?? '';
  String? get baseUrl => providers[activeProvider]?.baseUrl;

  AiProviderConfigEntity? get activeProviderConfig => providers[activeProvider];

  AiConfigEntity copyWith({
    String? activeProvider,
    String? activeModel,
    Map<String, AiProviderConfigEntity>? providers,
  }) {
    return AiConfigEntity(
      activeProvider: activeProvider ?? this.activeProvider,
      activeModel: activeModel ?? this.activeModel,
      providers: providers ?? this.providers,
    );
  }
}
