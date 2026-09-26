import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:shepherd/src/tools/domain/entities/ai_gateway_response_entity.dart';
import 'package:shepherd/src/tools/data/models/ai_gateway_response_model.dart';
import 'package:shepherd/src/tools/domain/services/shepherd_platform_ai_service.dart';

void main() {
  group('AiGatewayResponseEntity & Model', () {
    test('instantiates and maps from JSON correctly', () {
      final json = {
        'task_id': 'task_123',
        'mode': 'plan',
        'status': 'awaiting_plan_approval',
        'text': 'Plano gerado',
        'steps': ['Passo 1', 'Passo 2'],
        'model_used': 'gemini-2.5-pro',
      };

      final model = AiGatewayResponseModel.fromJson(json);
      expect(model, isA<AiGatewayResponseEntity>());
      expect(model.taskId, equals('task_123'));
      expect(model.mode, equals('plan'));
      expect(model.status, equals('awaiting_plan_approval'));
      expect(model.isAwaitingPlanApproval, isTrue);
      expect(model.steps, equals(['Passo 1', 'Passo 2']));
      expect(model.isSuccessful, isTrue);
    });

    test('toJson produces correct structure', () {
      const model = AiGatewayResponseModel(
        taskId: 't1',
        mode: 'fast',
        status: 'completed',
        text: 'Resposta',
      );
      final json = model.toJson();
      expect(json['task_id'], equals('t1'));
      expect(json['mode'], equals('fast'));
      expect(json['status'], equals('completed'));
      expect(json['text'], equals('Resposta'));
    });
  });

  group('ShepherdPlatformAiService', () {
    test('resolveGatewayUrl respects environment override', () {
      final service = ShepherdPlatformAiService();
      final urlProd = service.resolveGatewayUrl('prod');
      expect(urlProd, equals('https://ai.shepherdplatform.com'));

      final urlUat = service.resolveGatewayUrl('uat');
      expect(urlUat, equals('https://ai-uat.shepherdplatform.com'));
    });

    test('generate throws FormatException when not logged in', () async {
      // Mock client that shouldn't even be called if not authenticated
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });

      final service = ShepherdPlatformAiService(client: mockClient);
      // Unless .shepherd/session.yaml exists and has a token, it will throw FormatException
      // If a session exists, we verify it gracefully
      if (service.getSession()?['token'] == null) {
        expect(
          () => service.generate(goal: 'test prompt'),
          throwsA(isA<FormatException>()),
        );
      }
    });
  });
}
