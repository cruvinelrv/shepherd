import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shepherd/src/tools/data/models/mcp_server_config_model.dart';
import 'package:shepherd/src/tools/domain/services/mcp_client_service.dart';
import 'package:test/test.dart';

void main() {
  test('McpClientService handles Streamable HTTP, headers, and Mcp-Session-Id', () async {
    final seenAuth = <String>[];
    final seenSession = <String?>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    server.listen((req) async {
      seenAuth.add(req.headers.value('authorization') ?? '');
      seenSession.add(req.headers.value('mcp-session-id'));
      final body = jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>;
      final method = body['method'] as String?;

      req.response.headers.set('content-type', 'application/json');
      if (method == 'initialize') {
        req.response.headers.set('Mcp-Session-Id', 'sess-123');
        req.response.write(jsonEncode({
          'jsonrpc': '2.0',
          'id': body['id'],
          'result': {'protocolVersion': '2024-11-05', 'capabilities': {}},
        }));
      } else if (method == 'notifications/initialized') {
        req.response.statusCode = 202;
      } else if (method == 'tools/list') {
        req.response.write(jsonEncode({
          'jsonrpc': '2.0',
          'id': body['id'],
          'result': {
            'tools': [
              {'name': 'hub_create_repo', 'description': 'Create repo'},
            ],
          },
        }));
      } else if (method == 'tools/call') {
        final params = body['params'] as Map<String, dynamic>;
        final args = params['arguments'] as Map<String, dynamic>;
        req.response.write(jsonEncode({
          'jsonrpc': '2.0',
          'id': body['id'],
          'result': {
            'content': [
              {'type': 'text', 'text': 'created ${args['name']}'},
            ],
          },
        }));
      }
      await req.response.close();
    });

    final cfg = McpServerConfigModel.fromJson('marmelo', {
      'url': 'http://127.0.0.1:${server.port}/mcp',
      'headers': {'Authorization': 'Bearer mhub_test'},
    });
    expect(cfg.isHttp, isTrue);

    final tools = await McpClientService.listToolsForServer(cfg);
    expect(tools.map((t) => t.name), ['hub_create_repo']);
    expect(seenAuth.every((a) => a == 'Bearer mhub_test'), isTrue);
    expect(seenSession.contains('sess-123'), isTrue);

    final out = await McpClientService.callTool(cfg, 'hub_create_repo', {'name': 'app'});
    expect(out, 'created app');
  });

  test('saveGlobalServer persists config with headers to mcp.json', () {
    final tmp = Directory.systemTemp.createTempSync('shepherd_mcp_save_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    const cfg = McpServerConfigModel(
      id: 'marmelo',
      name: 'marmelo',
      transport: 'http',
      url: 'https://mcp.marmelo.tech/mcp',
      headers: {'Authorization': 'Bearer mhub_abc'},
    );
    McpClientService.saveGlobalServer(cfg, homePath: tmp.path);

    final saved = File(p.join(tmp.path, '.shepherd', 'mcp.json'));
    expect(saved.existsSync(), isTrue);
    final decoded = jsonDecode(saved.readAsStringSync()) as Map<String, dynamic>;
    final marmelo = (decoded['mcpServers'] as Map)['marmelo'] as Map;
    expect(marmelo['url'], 'https://mcp.marmelo.tech/mcp');
    expect((marmelo['headers'] as Map)['Authorization'], 'Bearer mhub_abc');
  });
}
