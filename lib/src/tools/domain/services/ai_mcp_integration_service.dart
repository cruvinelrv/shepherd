import 'dart:convert';
import '../../data/models/ai_mcp_tool_call_model.dart';
import '../../domain/entities/mcp_tool_entity.dart';
import 'mcp_client_service.dart';

/// Service responsible for integrating MCP (Model Context Protocol) tools
/// into the Shepherd AI reasoning and chat execution loop.
class AiMcpIntegrationService {
  /// Discovers and loads all configured MCP tools across registered servers.
  static Future<List<McpToolEntity>> loadTools({String? basePath}) async {
    try {
      return await McpClientService.discoverAllTools(basePath: basePath);
    } catch (_) {
      return [];
    }
  }

  /// Formats system prompt instructions and MCP tools catalog for the model.
  static String formatToolsInstruction(List<McpToolEntity> tools) {
    if (tools.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('--- Available Workspace MCP Tools ---');
    buffer.writeln('You have access to invoke MCP tools to inspect, test, or query the environment.');
    buffer.writeln('To call a tool, output the following exact block in your response:');
    buffer.writeln('<tool_call server="server_name" name="tool_name">');
    buffer.writeln('{"param": "value"}');
    buffer.writeln('</tool_call>');
    buffer.writeln();
    buffer.writeln('Registered tools:');
    for (final tool in tools) {
      buffer.writeln('• Server: [${tool.serverName}] | Tool: `${tool.name}`');
      if (tool.description != null && tool.description!.isNotEmpty) {
        buffer.writeln('  Description: ${tool.description}');
      }
      if (tool.inputSchema.isNotEmpty) {
        buffer.writeln('  Parameters (JSON Schema): ${jsonEncode(tool.inputSchema)}');
      }
    }
    buffer.writeln('--------------------------------------------------');
    return buffer.toString().trim();
  }

  /// Extracts MCP tool calls emitted by the model in `<tool_call ...>...</tool_call>` format.
  static List<AiMcpToolCallModel> extractToolCalls(String text) {
    final regex = RegExp(
      r'<tool_call\s+server="([^"]+)"\s+name="([^"]+)">([\s\S]*?)<\/tool_call>',
      caseSensitive: false,
    );

    final calls = <AiMcpToolCallModel>[];
    for (final match in regex.allMatches(text)) {
      final server = match.group(1)?.trim() ?? '';
      final name = match.group(2)?.trim() ?? '';
      final rawArgs = match.group(3)?.trim() ?? '{}';

      Map<String, dynamic> parsedArgs = {};
      try {
        final decoded = jsonDecode(rawArgs);
        if (decoded is Map) {
          parsedArgs = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}

      if (server.isNotEmpty && name.isNotEmpty) {
        calls.add(AiMcpToolCallModel(
          serverName: server,
          toolName: name,
          arguments: parsedArgs,
        ));
      }
    }

    return calls;
  }

  /// Executes an MCP tool call and returns the formatted response string.
  static Future<String> executeToolCall(
    AiMcpToolCallModel call, {
    String? basePath,
  }) async {
    final configs = McpClientService.loadConfigs(basePath: basePath);
    final targetConfig = configs.firstWhere(
      (c) => c.name.toLowerCase() == call.serverName.toLowerCase(),
      orElse: () => throw StateError('MCP Server "${call.serverName}" not found in configuration.'),
    );

    try {
      return await McpClientService.callTool(
        targetConfig,
        call.toolName,
        call.arguments,
      );
    } catch (e) {
      return 'Error executing MCP tool: $e';
    }
  }
}
