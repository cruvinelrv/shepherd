/// Entity representing a tool exposed by an MCP (Model Context Protocol) server.
class McpToolEntity {
  final String serverName;
  final String name;
  final String? description;
  final Map<String, dynamic> inputSchema;

  const McpToolEntity({
    required this.serverName,
    required this.name,
    this.description,
    this.inputSchema = const {},
  });
}
