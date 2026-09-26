import '../../domain/entities/mcp_server_config_entity.dart';

/// Data model for McpServerConfigEntity with JSON serialization.
/// Directly compatible with Shepherd Studio Engine (pkg/mcpclient/registry.go)
/// and standard MCP JSON structures.
class McpServerConfigModel extends McpServerConfigEntity {
  const McpServerConfigModel({
    required super.id,
    required super.name,
    super.transport = 'stdio',
    super.command,
    super.args = const [],
    super.url,
    super.env = const {},
    super.enabled = true,
  });

  factory McpServerConfigModel.fromJson(String idOrName, Map<String, dynamic> json) {
    final rawArgs = json['args'];
    final args = rawArgs is List ? rawArgs.map((e) => e.toString()).toList() : <String>[];

    final rawEnv = json['env'];
    final env = rawEnv is Map
        ? rawEnv.map((k, v) => MapEntry(k.toString(), v.toString()))
        : <String, String>{};

    final id = json['id']?.toString() ?? idOrName;
    final name = json['name']?.toString() ?? idOrName;
    final transport = json['transport']?.toString().toLowerCase() ?? 'stdio';
    final command = json['command']?.toString();
    final url = json['url']?.toString();

    // In Studio Engine, 'enabled' is boolean. In standard MCP json, 'disabled' is sometimes used.
    final bool isEnabled;
    if (json.containsKey('enabled')) {
      isEnabled = json['enabled'] == true;
    } else if (json.containsKey('disabled')) {
      isEnabled = json['disabled'] != true;
    } else {
      isEnabled = true;
    }

    return McpServerConfigModel(
      id: id,
      name: name,
      transport: transport,
      command: command,
      args: args,
      url: url,
      env: env,
      enabled: isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'transport': transport,
      if (command != null && command!.isNotEmpty) 'command': command,
      if (args.isNotEmpty) 'args': args,
      if (url != null && url!.isNotEmpty) 'url': url,
      if (env.isNotEmpty) 'env': env,
      'enabled': enabled,
    };
  }
}
