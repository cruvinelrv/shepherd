import 'dart:convert';
import '../../domain/entities/ai_mcp_tool_call_entity.dart';

class AiMcpToolCallModel extends AiMcpToolCallEntity {
  const AiMcpToolCallModel({
    required super.serverName,
    required super.toolName,
    required super.arguments,
  });

  factory AiMcpToolCallModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> args = {};
    final rawArgs = json['arguments'] ?? json['args'];
    if (rawArgs is Map) {
      args = Map<String, dynamic>.from(rawArgs);
    } else if (rawArgs is String && rawArgs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawArgs);
        if (decoded is Map) args = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    return AiMcpToolCallModel(
      serverName: json['server']?.toString() ?? json['serverName']?.toString() ?? '',
      toolName: json['name']?.toString() ?? json['toolName']?.toString() ?? '',
      arguments: args,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server': serverName,
      'name': toolName,
      'arguments': arguments,
    };
  }
}
