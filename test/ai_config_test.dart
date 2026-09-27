import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/tools/data/models/ai_config_model.dart';
import 'package:shepherd/src/tools/data/models/ai_token_usage_model.dart';
import 'package:shepherd/src/tools/domain/services/ai_model_catalog_service.dart';
import 'package:shepherd/src/tools/domain/services/ollama_url_helper.dart';

void main() {
  group('AiConfigModel', () {
    test('carrega formato legado com retrocompatibilidade total', () {
      const yamlStr = '''
provider: gemini
model: gemini-3.8-flash
apiKey: AIzaSyTestKey123
''';
      final loaded = loadYaml(yamlStr);
      final config = AiConfigModel.fromYaml(loaded);

      expect(config.activeProvider, equals('gemini'));
      expect(config.activeModel, equals('gemini-3.8-flash'));
      expect(config.provider, equals('gemini'));
      expect(config.model, equals('gemini-3.8-flash'));
      expect(config.apiKey, equals('AIzaSyTestKey123'));
      expect(config.providers.containsKey('gemini'), isTrue);
    });

    test('carrega e serializa formato multi-provedor novo', () {
      const yamlStr = '''
active_provider: openai
active_model: gpt-4o
providers:
  gemini:
    apiKey: AIzaSy111
    default_model: gemini-2.5-flash
    known_models:
      - gemini-2.5-flash
      - gemini-2.5-pro
  openai:
    apiKey: sk-proj-222
    default_model: gpt-4o
    known_models:
      - gpt-4o
      - o3-mini
  ollama:
    baseUrl: http://localhost:11434
    default_model: llama3.1
''';
      final loaded = loadYaml(yamlStr);
      final config = AiConfigModel.fromYaml(loaded);

      expect(config.activeProvider, equals('openai'));
      expect(config.activeModel, equals('gpt-4o'));
      expect(config.apiKey, equals('sk-proj-222'));
      expect(config.providers.length, equals(3));

      final gemini = config.providers['gemini']!;
      expect(gemini.apiKey, equals('AIzaSy111'));
      expect(gemini.defaultModel, equals('gemini-2.5-flash'));
      expect(gemini.knownModels, contains('gemini-2.5-pro'));

      final ollama = config.providers['ollama']!;
      expect(ollama.baseUrl, equals('http://localhost:11434'));
      expect(ollama.defaultModel, equals('llama3.1'));

      final map = config.toMap();
      expect(map['active_provider'], equals('openai'));
      expect(map['active_model'], equals('gpt-4o'));
      expect((map['providers'] as Map)['gemini']['apiKey'], equals('AIzaSy111'));
    });

    test('carrega e resolve perfis de slots multilíngues (EN / PT / ES)', () {
      const yamlStr = '''
active_profile: medium
slots:
  advanced:
    provider: anthropic
    model: claude-3-7-sonnet
  medium:
    provider: gemini
    model: gemini-2.5-flash
  local:
    provider: local_ai
    model: deepseek-r1
providers:
  gemini:
    apiKey: key1
    default_model: gemini-2.5-flash
  anthropic:
    apiKey: key2
    default_model: claude-3-7-sonnet
  local_ai:
    baseUrl: http://192.168.1.100:1234/v1
    default_model: deepseek-r1
''';
      final loaded = loadYaml(yamlStr);
      final config = AiConfigModel.fromYaml(loaded);

      expect(config.activeProfile, equals('medium'));
      expect(config.advanced?.model, equals('claude-3-7-sonnet'));
      expect(config.medium?.model, equals('gemini-2.5-flash'));
      expect(config.local?.model, equals('deepseek-r1'));

      // Resolução multilíngue para Advanced
      expect(config.resolveProfileSlot('advanced').model, equals('claude-3-7-sonnet'));
      expect(config.resolveProfileSlot('avancado').model, equals('claude-3-7-sonnet'));
      expect(config.resolveProfileSlot('avanzado').model, equals('claude-3-7-sonnet'));
      expect(config.resolveProfileSlot('deep').model, equals('claude-3-7-sonnet'));

      // Resolução multilíngue para Medium
      expect(config.resolveProfileSlot('medium').model, equals('gemini-2.5-flash'));
      expect(config.resolveProfileSlot('medio').model, equals('gemini-2.5-flash'));
      expect(config.resolveProfileSlot('fast').model, equals('gemini-2.5-flash'));

      // Resolução multilíngue para Local
      expect(config.resolveProfileSlot('local').model, equals('deepseek-r1'));
    });
  });

  group('AiModelCatalogService', () {
    test('retorna modelos padrão e adiciona modelos customizados do usuário', () {
      final models = AiModelCatalogService.getKnownModels(
        'gemini',
        userModels: ['gemini-custom-experiment'],
      );

      expect(models, contains('gemini-2.5-flash'));
      expect(models, contains('gemini-custom-experiment'));
    });
  });

  group('AiTokenUsageModel', () {
    test('formata e diferencia tokens locais gratuitos vs API pagos', () {
      final localUsage = AiTokenUsageModel(
        promptTokens: 200,
        completionTokens: 50,
        totalTokens: 250,
        isLocal: true,
      );
      expect(localUsage.isLocal, isTrue);
      expect(localUsage.typeLabel, equals('Local / Gratuito'));
      expect(localUsage.formatDetailed(), equals('250 [200p + 50c] (Local / Gratuito)'));

      final paidUsage = AiTokenUsageModel(
        promptTokens: 1000,
        completionTokens: 300,
        totalTokens: 1300,
        isLocal: false,
      );
      expect(paidUsage.isLocal, isFalse);
      expect(paidUsage.typeLabel, equals('API / Pago'));
      expect(paidUsage.formatDetailed(), equals('1300 [1000p + 300c] (API / Pago)'));
    });

    test('estima tokens corretamente com fallback proporcional', () {
      final estimated = AiTokenUsageModel.estimate(
        prompt: '12345678', // 8 chars -> 2 tokens
        completion: '1234', // 4 chars -> 1 token
        isLocal: false,
      );
      expect(estimated.promptTokens, equals(2));
      expect(estimated.completionTokens, equals(1));
      expect(estimated.totalTokens, equals(3));
      expect(estimated.isLocal, isFalse);
    });
  });

  group('OllamaUrlHelper', () {
    test('normaliza URLs locais e em máquinas na rede local (LAN)', () {
      expect(OllamaUrlHelper.normalize(null), equals('http://localhost:11434'));
      expect(OllamaUrlHelper.normalize(''), equals('http://localhost:11434'));
      expect(OllamaUrlHelper.normalize('192.168.1.50:11434'), equals('http://192.168.1.50:11434'));
      expect(OllamaUrlHelper.normalize('http://192.168.1.50:11434/'), equals('http://192.168.1.50:11434'));
      expect(OllamaUrlHelper.normalize('my-gpu.local:11434'), equals('http://my-gpu.local:11434'));
      expect(OllamaUrlHelper.normalize('https://custom-ollama.internal:11434///'), equals('https://custom-ollama.internal:11434'));
    });
  });
}
