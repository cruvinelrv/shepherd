import 'package:yaml/yaml.dart';
import '../../domain/entities/ai_config_entity.dart';

class AiProviderConfigModel extends AiProviderConfigEntity {
  const AiProviderConfigModel({
    required super.id,
    super.apiKey,
    super.baseUrl,
    required super.defaultModel,
    super.knownModels = const [],
  });

  factory AiProviderConfigModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final known = <String>[];
    if (map['known_models'] is List) {
      for (final item in map['known_models'] as List) {
        if (item != null) known.add(item.toString());
      }
    }

    return AiProviderConfigModel(
      id: id,
      apiKey: map['apiKey']?.toString() ?? map['api_key']?.toString(),
      baseUrl: map['baseUrl']?.toString() ?? map['base_url']?.toString(),
      defaultModel: map['default_model']?.toString() ??
          map['model']?.toString() ??
          _defaultModelFor(id),
      knownModels: known,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'default_model': defaultModel,
    };
    if (apiKey != null && apiKey!.isNotEmpty) {
      map['apiKey'] = apiKey;
    }
    if (baseUrl != null && baseUrl!.isNotEmpty) {
      map['baseUrl'] = baseUrl;
    }
    if (knownModels.isNotEmpty) {
      map['known_models'] = knownModels;
    }
    return map;
  }

  static String _defaultModelFor(String providerId) {
    switch (providerId.toLowerCase()) {
      case 'gemini':
        return 'gemini-2.5-flash';
      case 'openai':
        return 'gpt-4o';
      case 'anthropic':
        return 'claude-3-7-sonnet';
      case 'ollama':
        return 'llama3.1';
      default:
        return 'default';
    }
  }
}

class AiModelSlotModel extends AiModelSlotEntity {
  const AiModelSlotModel({
    required super.provider,
    required super.model,
  });

  factory AiModelSlotModel.fromMap(Map<dynamic, dynamic> map) {
    return AiModelSlotModel(
      provider: map['provider']?.toString() ?? 'gemini',
      model: map['model']?.toString() ?? 'gemini-2.5-flash',
    );
  }

  Map<String, dynamic> toMap() => {
    'provider': provider,
    'model': model,
  };
}

class AiConfigModel extends AiConfigEntity {
  const AiConfigModel({
    required super.activeProvider,
    required super.activeModel,
    super.activeProfile = 'medium',
    super.advanced,
    super.medium,
    super.local,
    super.providers = const {},
  });

  /// Construtor de compatibilidade para código que instanciou AiConfig(provider: ..., model: ..., apiKey: ...)
  factory AiConfigModel.legacy({
    required String provider,
    required String model,
    required String apiKey,
  }) {
    return AiConfigModel(
      activeProvider: provider,
      activeModel: model,
      providers: {
        provider: AiProviderConfigModel(
          id: provider,
          apiKey: apiKey,
          defaultModel: model,
          knownModels: [model],
        ),
      },
    );
  }

  factory AiConfigModel.fromYaml(dynamic loaded) {
    if (loaded is! YamlMap && loaded is! Map) {
      throw const FormatException('Formato YAML inválido para AiConfigModel');
    }

    final map = loaded is YamlMap ? Map<String, dynamic>.from(loaded) : loaded as Map<String, dynamic>;

    // 1. Formato novo com múltiplos provedores e slots
    if (map.containsKey('active_provider') || map.containsKey('providers') || map.containsKey('slots')) {
      final activeProvider = map['active_provider']?.toString() ?? 'gemini';
      final activeModel = map['active_model']?.toString() ?? 'gemini-2.5-flash';
      final activeProfile = map['active_profile']?.toString() ?? 'medium';
      final providersMap = <String, AiProviderConfigEntity>{};

      if (map['providers'] is Map) {
        final rawProviders = map['providers'] as Map;
        for (final entry in rawProviders.entries) {
          final id = entry.key.toString();
          if (entry.value is Map) {
            providersMap[id] = AiProviderConfigModel.fromMap(
              id,
              entry.value as Map,
            );
          }
        }
      }

      // Garante que o provedor ativo está no mapa
      if (!providersMap.containsKey(activeProvider)) {
        providersMap[activeProvider] = AiProviderConfigModel(
          id: activeProvider,
          defaultModel: activeModel,
        );
      }

      AiModelSlotModel? advanced;
      AiModelSlotModel? medium;
      AiModelSlotModel? local;

      if (map['slots'] is Map) {
        final slots = map['slots'] as Map;
        if (slots['advanced'] is Map) {
          advanced = AiModelSlotModel.fromMap(slots['advanced'] as Map);
        }
        if (slots['medium'] is Map) {
          medium = AiModelSlotModel.fromMap(slots['medium'] as Map);
        }
        if (slots['local'] is Map) {
          local = AiModelSlotModel.fromMap(slots['local'] as Map);
        }
      }

      return AiConfigModel(
        activeProvider: activeProvider,
        activeModel: activeModel,
        activeProfile: activeProfile,
        advanced: advanced,
        medium: medium,
        local: local,
        providers: providersMap,
      );
    }

    // 2. Formato legado (provider, model, apiKey)
    final provider = map['provider']?.toString() ?? 'gemini';
    final model = map['model']?.toString() ?? 'gemini-2.5-flash';
    final apiKey = map['apiKey']?.toString() ?? map['api_key']?.toString() ?? '';

    return AiConfigModel.legacy(
      provider: provider,
      model: model,
      apiKey: apiKey,
    );
  }

  Map<String, dynamic> toMap() {
    final providersData = <String, dynamic>{};
    for (final entry in providers.entries) {
      if (entry.value is AiProviderConfigModel) {
        providersData[entry.key] = (entry.value as AiProviderConfigModel).toMap();
      } else {
        providersData[entry.key] = AiProviderConfigModel(
          id: entry.value.id,
          apiKey: entry.value.apiKey,
          baseUrl: entry.value.baseUrl,
          defaultModel: entry.value.defaultModel,
          knownModels: entry.value.knownModels,
        ).toMap();
      }
    }

    final slotsData = <String, dynamic>{};
    if (advanced != null) {
      slotsData['advanced'] = (advanced is AiModelSlotModel)
          ? (advanced as AiModelSlotModel).toMap()
          : {'provider': advanced!.provider, 'model': advanced!.model};
    }
    if (medium != null) {
      slotsData['medium'] = (medium is AiModelSlotModel)
          ? (medium as AiModelSlotModel).toMap()
          : {'provider': medium!.provider, 'model': medium!.model};
    }
    if (local != null) {
      slotsData['local'] = (local is AiModelSlotModel)
          ? (local as AiModelSlotModel).toMap()
          : {'provider': local!.provider, 'model': local!.model};
    }

    return {
      'active_provider': activeProvider,
      'active_model': activeModel,
      'active_profile': activeProfile,
      if (slotsData.isNotEmpty) 'slots': slotsData,
      'providers': providersData,
    };
  }

  @override
  AiConfigModel copyWith({
    String? activeProvider,
    String? activeModel,
    String? activeProfile,
    AiModelSlotEntity? advanced,
    AiModelSlotEntity? medium,
    AiModelSlotEntity? local,
    Map<String, AiProviderConfigEntity>? providers,
  }) {
    return AiConfigModel(
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

