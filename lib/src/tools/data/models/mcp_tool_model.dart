import '../../domain/entities/mcp_tool_entity.dart';

/// Data model for McpToolEntity with JSON serialization.
class McpToolModel extends McpToolEntity {
  const McpToolModel({
    required super.serverName,
    required super.name,
    super.description,
    super.inputSchema = const {},
  });

  factory McpToolModel.fromJson(String serverName, Map<String, dynamic> json) {
    final rawSchema = json['inputSchema'];
    final schema = rawSchema is Map<String, dynamic>
        ? rawSchema
        : (rawSchema is Map ? Map<String, dynamic>.from(rawSchema) : <String, dynamic>{});

    return McpToolModel(
      serverName: serverName,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      inputSchema: schema,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverName': serverName,
      'name': name,
      if (description != null) 'description': description,
      'inputSchema': inputSchema,
    };
  }
}
