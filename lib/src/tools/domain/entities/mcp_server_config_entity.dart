/// Configuration entity for an MCP (Model Context Protocol) server.
/// 100% interoperable with Shepherd Studio Engine (pkg/mcpclient) and Shepherd Intelligence.
class McpServerConfigEntity {
  final String id;
  final String name;
  final String transport; // "stdio" or "http"
  final String? command;
  final List<String> args;
  final String? url;
  final Map<String, String> env;
  final bool enabled;

  const McpServerConfigEntity({
    required this.id,
    required this.name,
    this.transport = 'stdio',
    this.command,
    this.args = const [],
    this.url,
    this.env = const {},
    this.enabled = true,
  });

  bool get isHttp => transport.toLowerCase() == 'http';
  bool get isStdio => !isHttp;
}
