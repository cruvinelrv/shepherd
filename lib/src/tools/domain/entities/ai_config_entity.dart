class AiModelSlotEntity {
  final String provider;
  final String model;

  const AiModelSlotEntity({
    required this.provider,
    required this.model,
  });

  AiModelSlotEntity copyWith({
    String? provider,
    String? model,
  }) {
    return AiModelSlotEntity(
      provider: provider ?? this.provider,
      model: model ?? this.model,
    );
  }
}

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
  final String activeProfile; // 'medium', 'advanced', 'local'
  final AiModelSlotEntity? advanced;
  final AiModelSlotEntity? medium;
  final AiModelSlotEntity? local;
  final Map<String, AiProviderConfigEntity> providers;

  const AiConfigEntity({
    required this.activeProvider,
    required this.activeModel,
    this.activeProfile = 'medium',
    this.advanced,
    this.medium,
    this.local,
    this.providers = const {},
  });

  // Getters for backwards compatibility
  String get provider => activeProvider;
  String get model => activeModel;
  String get apiKey => providers[activeProvider]?.apiKey ?? '';
  String? get baseUrl => providers[activeProvider]?.baseUrl;

  AiProviderConfigEntity? get activeProviderConfig => providers[activeProvider];

  /// Resolves the model slot corresponding to the requested profile,
  /// supporting identifiers in English, Portuguese, or Spanish.
  AiModelSlotEntity resolveProfileSlot([String? profileName]) {
    final target = (profileName ?? activeProfile).toLowerCase();
    switch (target) {
      case 'advanced':
      case 'avancado':
      case 'avanzado':
      case 'deep':
        return advanced ??
            AiModelSlotEntity(
              provider: providers.containsKey('anthropic')
                  ? 'anthropic'
                  : (providers.containsKey('openai') ? 'openai' : 'gemini'),
              model: providers.containsKey('anthropic')
                  ? 'claude-3-7-sonnet'
                  : (providers.containsKey('openai') ? 'gpt-4o' : 'gemini-2.5-pro'),
            );
      case 'local':
        return local ??
            AiModelSlotEntity(
              provider: providers.containsKey('local_ai') ? 'local_ai' : 'ollama',
              model: providers.containsKey('local_ai') ? 'local-model' : 'llama3.1',
            );
      case 'medium':
      case 'medio':
      case 'fast':
      default:
        return medium ??
            AiModelSlotEntity(
              provider: activeProvider.isNotEmpty ? activeProvider : 'gemini',
              model: activeModel.isNotEmpty ? activeModel : 'gemini-2.5-flash',
            );
    }
  }

  AiConfigEntity copyWith({
    String? activeProvider,
    String? activeModel,
    String? activeProfile,
    AiModelSlotEntity? advanced,
    AiModelSlotEntity? medium,
    AiModelSlotEntity? local,
    Map<String, AiProviderConfigEntity>? providers,
  }) {
    return AiConfigEntity(
      activeProvider: activeProvider ?? this.activeProvider,
      activeModel: activeModel ?? this.activeModel,
      activeProfile: activeProfile ?? this.activeProfile,
      advanced: advanced ?? this.advanced,
      medium: medium ?? this.medium,
      local: local ?? this.local,
      providers: providers ?? this.providers,
    );
  }
}
