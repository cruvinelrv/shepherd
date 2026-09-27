import 'package:shepherd/src/tools/domain/services/ai_model_catalog_service.dart';
import 'package:shepherd/src/tools/domain/services/ollama_url_helper.dart';
import 'package:test/test.dart';

void main() {
  group('LanAiHelper', () {
    test('isLocalOrLan correctly identifies loopback and LAN IP addresses', () {
      expect(LanAiHelper.isLocalOrLan('localhost'), isTrue);
      expect(LanAiHelper.isLocalOrLan('127.0.0.1'), isTrue);
      expect(LanAiHelper.isLocalOrLan('0.0.0.0'), isTrue);
      expect(LanAiHelper.isLocalOrLan('::1'), isTrue);
      expect(LanAiHelper.isLocalOrLan('my-server.local'), isTrue);
      expect(LanAiHelper.isLocalOrLan('http://192.168.0.10:11434'), isTrue);
      expect(LanAiHelper.isLocalOrLan('http://192.168.1.150:1234/v1'), isTrue);
      expect(LanAiHelper.isLocalOrLan('http://10.0.1.20:8000/v1'), isTrue);
      expect(LanAiHelper.isLocalOrLan('http://172.16.5.2:1234'), isTrue);
      expect(LanAiHelper.isLocalOrLan('http://172.31.255.255:8080'), isTrue);
    });

    test('isLocalOrLan returns false for public/cloud API addresses', () {
      expect(LanAiHelper.isLocalOrLan('https://api.openai.com/v1'), isFalse);
      expect(LanAiHelper.isLocalOrLan('https://generativelanguage.googleapis.com'), isFalse);
      expect(LanAiHelper.isLocalOrLan('https://api.anthropic.com/v1'), isFalse);
      expect(LanAiHelper.isLocalOrLan('https://ai.shepherdplatform.com'), isFalse);
      expect(LanAiHelper.isLocalOrLan(''), isFalse);
    });

    test('buildChatCompletionsUrl formats endpoint properly', () {
      expect(
        LanAiHelper.buildChatCompletionsUrl('http://192.168.1.100:1234/v1'),
        equals('http://192.168.1.100:1234/v1/chat/completions'),
      );
      expect(
        LanAiHelper.buildChatCompletionsUrl('http://localhost:1234'),
        equals('http://localhost:1234/v1/chat/completions'),
      );
      expect(
        LanAiHelper.buildChatCompletionsUrl('http://10.0.0.5:8000/v1/chat/completions'),
        equals('http://10.0.0.5:8000/v1/chat/completions'),
      );
    });

    test('buildModelsUrl formats endpoint properly', () {
      expect(
        LanAiHelper.buildModelsUrl('http://192.168.1.100:1234/v1'),
        equals('http://192.168.1.100:1234/v1/models'),
      );
      expect(
        LanAiHelper.buildModelsUrl('http://localhost:1234'),
        equals('http://localhost:1234/v1/models'),
      );
      expect(
        LanAiHelper.buildModelsUrl('http://10.0.0.5:8000/models'),
        equals('http://10.0.0.5:8000/models'),
      );
    });

    test('AiModelCatalogService supplies default models for local_ai', () {
      final models = AiModelCatalogService.getKnownModels('local_ai');
      expect(models, isNotEmpty);
      expect(models, contains('local-model'));
    });
  });
}
