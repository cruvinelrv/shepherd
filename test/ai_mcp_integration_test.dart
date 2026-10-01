import 'package:test/test.dart';
import 'package:shepherd/src/tools/data/models/ai_mcp_tool_call_model.dart';
import 'package:shepherd/src/tools/domain/entities/mcp_tool_entity.dart';
import 'package:shepherd/src/tools/domain/services/ai_mcp_integration_service.dart';

void main() {
  group('AiMcpIntegrationService', () {
    test('formatToolsInstruction formata catálogo de ferramentas para o prompt', () {
      final tools = [
        const McpToolEntity(
          name: 'run_tests',
          description: 'Executa testes unitários',
          inputSchema: {'type': 'object'},
          serverName: 'test-runner',
        ),
      ];

      final instruction = AiMcpIntegrationService.formatToolsInstruction(tools);
      expect(instruction, contains('--- Available Workspace MCP Tools ---'));
      expect(instruction, contains('test-runner'));
      expect(instruction, contains('run_tests'));
      expect(instruction, contains('<tool_call'));
    });

    test('extractToolCalls extrai chamadas de ferramentas emitidas no formato tag', () {
      const text = '''
Aqui está a minha análise. Vou rodar os testes para confirmar:
<tool_call server="shepherd-tools" name="execute_test">
{"suite": "unit", "filter": "auth"}
</tool_call>
Aguardando o resultado.
''';

      final calls = AiMcpIntegrationService.extractToolCalls(text);
      expect(calls.length, equals(1));
      expect(calls.first.serverName, equals('shepherd-tools'));
      expect(calls.first.toolName, equals('execute_test'));
      expect(calls.first.arguments['suite'], equals('unit'));
      expect(calls.first.arguments['filter'], equals('auth'));
    });

    test('AiMcpToolCallModel serializa e deserializa corretamente', () {
      final model = const AiMcpToolCallModel(
        serverName: 'my-server',
        toolName: 'my-tool',
        arguments: {'key': 'value'},
      );

      final json = model.toJson();
      expect(json['server'], equals('my-server'));
      expect(json['name'], equals('my-tool'));

      final fromJson = AiMcpToolCallModel.fromJson(json);
      expect(fromJson.serverName, equals('my-server'));
      expect(fromJson.toolName, equals('my-tool'));
      expect(fromJson.arguments['key'], equals('value'));
    });
  });
}
