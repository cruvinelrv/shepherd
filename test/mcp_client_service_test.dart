import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shepherd/src/tools/data/models/mcp_server_config_model.dart';
import 'package:shepherd/src/tools/data/models/mcp_tool_model.dart';
import 'package:shepherd/src/tools/domain/services/mcp_client_service.dart';

void main() {
  group('MCP Client & Registry Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('shepherd_mcp_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('McpServerConfigModel parses Shepherd Studio Engine mcp_servers.json format', () {
      final json = {
        'id': 'mcp_git',
        'name': 'Git Server',
        'transport': 'stdio',
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-git', '.'],
        'enabled': true,
      };

      final model = McpServerConfigModel.fromJson('mcp_git', json);
      expect(model.id, equals('mcp_git'));
      expect(model.name, equals('Git Server'));
      expect(model.transport, equals('stdio'));
      expect(model.command, equals('npx'));
      expect(model.args, equals(['-y', '@modelcontextprotocol/server-git', '.']));
      expect(model.enabled, isTrue);
      expect(model.isStdio, isTrue);
      expect(model.isHttp, isFalse);
    });

    test('McpServerConfigModel parses HTTP transport configuration', () {
      final json = {
        'id': 'remote_mcp',
        'name': 'Remote MCP Server',
        'transport': 'http',
        'url': 'https://mcp.internal.marmelotech.com.br/sse',
        'enabled': true,
      };

      final model = McpServerConfigModel.fromJson('remote_mcp', json);
      expect(model.isHttp, isTrue);
      expect(model.url, equals('https://mcp.internal.marmelotech.com.br/sse'));
    });

    test('McpToolModel maps tool json properly', () {
      final toolJson = {
        'name': 'git_status',
        'description': 'View git status',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'repo': {'type': 'string'},
          },
        },
      };

      final tool = McpToolModel.fromJson('git', toolJson);
      expect(tool.serverName, equals('git'));
      expect(tool.name, equals('git_status'));
      expect(tool.description, equals('View git status'));
      expect(tool.inputSchema['properties'], isNotNull);
    });

    test('McpClientService.loadConfigs reads .shepherd/mcp_servers.json', () {
      final shepherdDir = Directory('${tempDir.path}/.shepherd');
      shepherdDir.createSync(recursive: true);

      final mcpServersFile = File('${shepherdDir.path}/mcp_servers.json');
      final serversMap = {
        'mcp_1': {
          'id': 'mcp_1',
          'name': 'Test Server',
          'transport': 'stdio',
          'command': 'echo',
          'args': ['hello'],
          'enabled': true,
        },
        'mcp_2': {
          'id': 'mcp_2',
          'name': 'Disabled Server',
          'transport': 'stdio',
          'command': 'echo',
          'enabled': false,
        },
      };
      mcpServersFile.writeAsStringSync(jsonEncode(serversMap));

      final loaded = McpClientService.loadConfigs(basePath: tempDir.path);
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('mcp_1'));
      expect(loaded.first.name, equals('Test Server'));
    });

    test('McpClientService.formatToolsForPrompt formats tools cleanly', () {
      final tool = McpToolModel(
        serverName: 'git',
        name: 'git_status',
        description: 'View current git status',
        inputSchema: {
          'properties': {'repo': {}}
        },
      );

      final formatted = McpClientService.formatToolsForPrompt([tool]);
      expect(formatted, contains('git::git_status'));
      expect(formatted, contains('View current git status'));
      expect(formatted, contains('repo'));
    });
  });
}
