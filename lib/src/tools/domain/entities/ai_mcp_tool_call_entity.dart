class AiMcpToolCallEntity {
  final String serverName;
  final String toolName;
  final Map<String, dynamic> arguments;

  const AiMcpToolCallEntity({
    required this.serverName,
    required this.toolName,
    required this.arguments,
  });
}
