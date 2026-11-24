import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../../data/models/mcp_server_config_model.dart';
import '../../data/models/mcp_tool_model.dart';
import '../entities/mcp_server_config_entity.dart';
import '../entities/mcp_tool_entity.dart';

/// Service responsible for managing connections to MCP (Model Context Protocol) servers.
/// 100% interoperable with Shepherd Studio Engine (pkg/mcpclient) and Shepherd Intelligence,
/// reading and persisting server configurations from `mcp_servers.json` and `.shepherd/mcp.json`.
class McpClientService {
  /// Loads all configured and enabled MCP servers from:
  /// 1. `~/.shepherd/mcp_servers.json` (Shepherd Studio default global registry)
  /// 2. `.shepherd/mcp_servers.json` (Workspace registry)
  /// 3. `.shepherd/mcp.json` (Standard fallback)
  static List<McpServerConfigModel> loadConfigs({String? basePath}) {
    final configs = <String, McpServerConfigModel>{};
    final root = basePath ?? Directory.current.path;

    // 1. Global registry (~/.shepherd/mcp_servers.json)
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      final globalStudioFile = File(p.join(home, '.shepherd', 'mcp_servers.json'));
      _parseConfigFile(globalStudioFile, configs);

      final globalMcpFile = File(p.join(home, '.shepherd', 'mcp.json'));
      _parseConfigFile(globalMcpFile, configs);
    }

    // 2. Workspace/Project registry (.shepherd/mcp_servers.json & .shepherd/mcp.json)
    final localStudioFile = File(p.join(root, '.shepherd', 'mcp_servers.json'));
    _parseConfigFile(localStudioFile, configs);

    final localMcpFile = File(p.join(root, '.shepherd', 'mcp.json'));
    _parseConfigFile(localMcpFile, configs);

    return configs.values.where((c) => c.enabled).toList();
  }

  static void _parseConfigFile(File file, Map<String, McpServerConfigModel> target) {
    if (!file.existsSync()) return;
    try {
      final content = file.readAsStringSync();
      final dynamic parsed = jsonDecode(content);
      if (parsed is Map) {
        // Check if format is { "mcpServers": { ... } } (Standard MCP)
        if (parsed.containsKey('mcpServers') && parsed['mcpServers'] is Map) {
          final servers = parsed['mcpServers'] as Map;
          for (final entry in servers.entries) {
            final key = entry.key.toString();
            if (entry.value is Map) {
              target[key] = McpServerConfigModel.fromJson(
                key,
                Map<String, dynamic>.from(entry.value as Map),
              );
            }
          }
        } else {
          // Shepherd Studio Engine format: { "id1": { "id": "id1", "name": "...", ... } }
          for (final entry in parsed.entries) {
            final key = entry.key.toString();
            if (entry.value is Map) {
              target[key] = McpServerConfigModel.fromJson(
                key,
                Map<String, dynamic>.from(entry.value as Map),
              );
            }
          }
        }
      }
    } catch (_) {
      // Ignore corrupted or invalid JSON configs gracefully
    }
  }

  /// Lists all tools exposed by the given MCP server (either via stdio or http).
  static Future<List<McpToolEntity>> listToolsForServer(
    McpServerConfigEntity config, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (config.isHttp) {
      return _listToolsHttp(config, timeout: timeout);
    } else {
      return _listToolsStdio(config, timeout: timeout);
    }
  }

  /// Calls an MCP tool on the given server and returns the result as a string.
  static Future<String> callTool(
    McpServerConfigEntity config,
    String toolName,
    Map<String, dynamic> arguments, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (config.isHttp) {
      return _callToolHttp(config, toolName, arguments, timeout: timeout);
    } else {
      return _callToolStdio(config, toolName, arguments, timeout: timeout);
    }
  }

  /// Discovers all tools across all enabled MCP servers.
  static Future<List<McpToolEntity>> discoverAllTools({String? basePath}) async {
    final configs = loadConfigs(basePath: basePath);
    if (configs.isEmpty) return [];

    final allTools = <McpToolEntity>[];
    for (final config in configs) {
      try {
        final tools = await listToolsForServer(config);
        allTools.addAll(tools);
      } catch (_) {}
    }
    return allTools;
  }

  /// Formats a list of MCP tools into markdown documentation for AI prompt injection.
  static String formatToolsForPrompt(List<McpToolEntity> tools) {
    if (tools.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('### Available MCP tools (Shepherd Studio & CLI):');
    for (final tool in tools) {
      buffer.writeln(
          '- **`${tool.serverName}::${tool.name}`**: ${tool.description ?? "No description"}');
      if (tool.inputSchema.isNotEmpty && tool.inputSchema['properties'] is Map) {
        final props = (tool.inputSchema['properties'] as Map).keys.join(', ');
        buffer.writeln('  *Parameters*: ($props)');
      }
    }
    buffer.writeln('');
    return buffer.toString();
  }

  // --- stdio implementation ---

  static Future<List<McpToolEntity>> _listToolsStdio(
    McpServerConfigEntity config, {
    required Duration timeout,
  }) async {
    if (config.command == null || config.command!.isEmpty) return [];

    Process? process;
    try {
      process = await Process.start(
        config.command!,
        config.args,
        environment: config.env,
        mode: ProcessStartMode.normal,
      );

      final lines = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();

      // Handshake: initialize
      final initId = 1;
      process.stdin.writeln(jsonEncode({
        'jsonrpc': '2.0',
        'id': initId,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'shepherd-cli', 'version': '0.11.2'},
        },
      }));
      await process.stdin.flush();

      await _waitForResponse(lines, initId).timeout(timeout);

      process.stdin.writeln(jsonEncode({
        'jsonrpc': '2.0',
        'method': 'notifications/initialized',
      }));
      await process.stdin.flush();

      // Request tools/list
      final toolsId = 2;
      process.stdin.writeln(jsonEncode({
        'jsonrpc': '2.0',
        'id': toolsId,
        'method': 'tools/list',
        'params': {},
      }));
      await process.stdin.flush();

      final toolsResponse = await _waitForResponse(lines, toolsId).timeout(timeout);
      final toolsList = <McpToolEntity>[];

      if (toolsResponse['result'] is Map && toolsResponse['result']['tools'] is List) {
        final rawTools = toolsResponse['result']['tools'] as List;
        for (final item in rawTools) {
          if (item is Map) {
            toolsList.add(McpToolModel.fromJson(config.name, Map<String, dynamic>.from(item)));
          }
        }
      }

      return toolsList;
    } catch (_) {
      return [];
    } finally {
      process?.kill();
    }
  }

  static Future<String> _callToolStdio(
    McpServerConfigEntity config,
    String toolName,
    Map<String, dynamic> arguments, {
    required Duration timeout,
  }) async {
    if (config.command == null || config.command!.isEmpty) {
      return 'stdio command not configured for server ${config.name}';
    }

    Process? process;
    try {
      process = await Process.start(
        config.command!,
        config.args,
        environment: config.env,
        mode: ProcessStartMode.normal,
      );

      final lines = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();

      // Initialize
      process.stdin.writeln(jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'shepherd-cli', 'version': '0.11.2'},
        },
      }));
      await process.stdin.flush();
      await _waitForResponse(lines, 1).timeout(const Duration(seconds: 10));

      process.stdin.writeln(jsonEncode({
        'jsonrpc': '2.0',
        'method': 'notifications/initialized',
      }));
      await process.stdin.flush();

      // Call tool
      final callId = 2;
      process.stdin.writeln(jsonEncode({
        'jsonrpc': '2.0',
        'id': callId,
        'method': 'tools/call',
        'params': {
          'name': toolName,
          'arguments': arguments,
        },
      }));
      await process.stdin.flush();

      final response = await _waitForResponse(lines, callId).timeout(timeout);
      if (response['error'] != null) {
        return 'MCP error: ${response['error']['message'] ?? response['error']}';
      }

      final result = response['result'];
      if (result is Map && result['content'] is List) {
        final buffer = StringBuffer();
        for (final item in result['content'] as List) {
          if (item is Map && item['text'] != null) {
            buffer.writeln(item['text']);
          }
        }
        return buffer.toString().trim();
      }

      return jsonEncode(result);
    } catch (e) {
      return 'Falha ao executar ferramenta MCP [$toolName]: $e';
    } finally {
      process?.kill();
    }
  }

  // --- http implementation (Streamable HTTP + JSON-RPC) ---

  static Map<String, String> _httpHeaders(
    McpServerConfigEntity config, {
    String? sessionId,
  }) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream',
      ...config.headers,
      if (sessionId != null && sessionId.isNotEmpty) 'Mcp-Session-Id': sessionId,
    };
  }

  static dynamic _decodeMcpHttpBody(http.Response response) {
    final ct = (response.headers['content-type'] ?? '').toLowerCase();
    final body = response.body;
    final trimmed = body.trimLeft();
    if (ct.contains('text/event-stream') || trimmed.startsWith('event:') || trimmed.startsWith('data:')) {
      dynamic last;
      for (final line in LineSplitter.split(body)) {
        final trimmed = line.trim();
        if (trimmed.startsWith('data:')) {
          final payload = trimmed.substring(5).trim();
          if (payload.isEmpty || payload == '[DONE]') continue;
          try {
            last = jsonDecode(payload);
          } catch (_) {}
        }
      }
      if (last != null) return last;
    }
    return jsonDecode(body);
  }

  static Future<String?> _initHttpSession(
    Uri uri,
    McpServerConfigEntity config,
    Duration timeout,
  ) async {
    final initResp = await http
        .post(
          uri,
          headers: _httpHeaders(config),
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': 0,
            'method': 'initialize',
            'params': {
              'protocolVersion': '2024-11-05',
              'capabilities': {},
              'clientInfo': {'name': 'shepherd', 'version': '0.15.4'},
            },
          }),
        )
        .timeout(timeout);

    if (initResp.statusCode == 401 || initResp.statusCode == 403) {
      throw HttpException('HTTP ${initResp.statusCode} (não autorizado)', uri: uri);
    }
    if (initResp.statusCode < 200 || initResp.statusCode >= 300) {
      throw HttpException('HTTP ${initResp.statusCode}: ${initResp.body}', uri: uri);
    }

    String? sid;
    for (final entry in initResp.headers.entries) {
      if (entry.key.toLowerCase() == 'mcp-session-id') {
        sid = entry.value;
        break;
      }
    }

    try {
      await http
          .post(
            uri,
            headers: _httpHeaders(config, sessionId: sid),
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'notifications/initialized',
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    return sid;
  }

  static Future<List<McpToolEntity>> _listToolsHttp(
    McpServerConfigEntity config, {
    required Duration timeout,
  }) async {
    if (config.url == null || config.url!.isEmpty) return [];
    final uri = Uri.parse(config.url!);
    final sid = await _initHttpSession(uri, config, timeout);
    final response = await http
        .post(
          uri,
          headers: _httpHeaders(config, sessionId: sid),
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'method': 'tools/list',
            'params': {},
          }),
        )
        .timeout(timeout);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw HttpException('HTTP ${response.statusCode} (não autorizado)', uri: uri);
    }
    if (response.statusCode == 200) {
      final dynamic parsed = _decodeMcpHttpBody(response);
      if (parsed is Map && parsed['result'] is Map && parsed['result']['tools'] is List) {
        final toolsList = <McpToolEntity>[];
        for (final item in parsed['result']['tools'] as List) {
          if (item is Map) {
            toolsList.add(McpToolModel.fromJson(config.name, Map<String, dynamic>.from(item)));
          }
        }
        return toolsList;
      }
    }
    throw HttpException('HTTP ${response.statusCode}: ${response.body}', uri: uri);
  }

  static Future<String> _callToolHttp(
    McpServerConfigEntity config,
    String toolName,
    Map<String, dynamic> arguments, {
    required Duration timeout,
  }) async {
    if (config.url == null || config.url!.isEmpty) {
      return 'HTTP URL not configured for ${config.name}';
    }
    try {
      final uri = Uri.parse(config.url!);
      final sid = await _initHttpSession(uri, config, timeout);
      final response = await http
          .post(
            uri,
            headers: _httpHeaders(config, sessionId: sid),
            body: jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'method': 'tools/call',
              'params': {
                'name': toolName,
                'arguments': arguments,
              },
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final dynamic parsed = _decodeMcpHttpBody(response);
        if (parsed is Map) {
          if (parsed['error'] != null) {
            return 'MCP error: ${parsed['error']['message'] ?? parsed['error']}';
          }
          final result = parsed['result'];
          if (result is Map && result['content'] is List) {
            final buffer = StringBuffer();
            for (final item in result['content'] as List) {
              if (item is Map && item['text'] != null) {
                buffer.writeln(item['text']);
              }
            }
            return buffer.toString().trim();
          }
          return jsonEncode(result);
        }
      }
      return 'HTTP ${response.statusCode}: ${response.body}';
    } catch (e) {
      return 'Falha ao executar ferramenta MCP HTTP [$toolName]: $e';
    }
  }

  /// Persists or updates a server entry in `~/.shepherd/mcp.json` (or `home`).
  static void saveGlobalServer(McpServerConfigModel server, {String? homePath}) {
    final home = homePath ?? Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) {
      throw StateError('HOME não definido');
    }
    final file = File(p.join(home, '.shepherd', 'mcp.json'));
    file.parent.createSync(recursive: true);
    Map<String, dynamic> root = {};
    if (file.existsSync()) {
      try {
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is Map) root = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    final servers = root['mcpServers'] is Map
        ? Map<String, dynamic>.from(root['mcpServers'] as Map)
        : <String, dynamic>{};
    servers[server.id] = server.toJson();
    root['mcpServers'] = servers;
    file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(root)}\n');
  }

  static Future<Map<String, dynamic>> _waitForResponse(
    Stream<String> lines,
    int expectedId,
  ) {
    final completer = Completer<Map<String, dynamic>>();
    late StreamSubscription<String> sub;

    sub = lines.listen((line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) return;
      try {
        final dynamic parsed = jsonDecode(trimmed);
        if (parsed is Map && parsed['id'] == expectedId) {
          completer.complete(Map<String, dynamic>.from(parsed));
          sub.cancel();
        }
      } catch (_) {
        // Not a JSON-RPC response line, continue
      }
    }, onError: (err) {
      if (!completer.isCompleted) completer.completeError(err);
    }, onDone: () {
      if (!completer.isCompleted) {
        completer
            .completeError(StateError('Process stream ended without response for id $expectedId'));
      }
    });

    return completer.future;
  }
}
