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

class AiConfigModel extends AiConfigEntity {
  const AiConfigModel({
    required super.activeProvider,
    required super.activeModel,
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

    // 1. Formato novo com múltiplos provedores
    if (map.containsKey('active_provider') || map.containsKey('providers')) {
      final activeProvider = map['active_provider']?.toString() ?? 'gemini';
      final activeModel = map['active_model']?.toString() ?? 'gemini-2.5-flash';
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

      return AiConfigModel(
        activeProvider: activeProvider,
        activeModel: activeModel,
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

    return {
      'active_provider': activeProvider,
      'active_model': activeModel,
      'providers': providersData,
    };
  }
}
