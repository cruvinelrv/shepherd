import 'dart:io';

import '../version.dart';
import 'rpc_client.dart';
import 'session_reader.dart';

/// A running engine with an initialized conversation.
class EngineSession {
  final RpcClient client;
  String provider;
  String model;
  String mode;
  List<String> projects;
  final bool offline;

  EngineSession._(this.client, this.provider, this.model, this.mode,
      this.projects, this.offline);

  /// Starts [exe], and says hello with the user's login. Throws [RpcException]
  /// when the engine refuses (no login, nothing configured, ...).
  static Future<EngineSession> start({
    required File exe,
    required LoginSession login,
    String? workspace,
    String? provider,
    String? model,
    String mode = 'fast',
    List<String> projects = const [],
    bool? rag,
  }) async {
    final client = await RpcClient.start(exe.path);
    try {
      final r = await client.request('initialize', {
        'protocolVersion': 2,
        'clientInfo': {'name': 'shepherd-cli', 'version': shepherdVersion},
        'workspaceRoot': workspace ?? Directory.current.path,
        'projects': projects,
        'mode': mode,
        if (provider != null) 'provider': provider,
        if (model != null) 'model': model,
        if (rag != null) 'rag': rag,
        'auth': login.toAuth(),
      });
      final s = (r['session'] as Map?)?.cast<String, dynamic>() ?? const {};
      return EngineSession._(
        client,
        '${s['provider']}',
        '${s['model']}',
        '${s['mode'] ?? mode}',
        ((s['projects'] as List?) ?? const []).map((e) => '$e').toList(),
        (r['auth'] as Map?)?['offline'] == true,
      );
    } catch (_) {
      await client.close();
      rethrow;
    }
  }

  Future<void> setMode(String m) async {
    final r = await client.request('session/setMode', {'mode': m});
    mode = '${r['mode']}';
  }

  Future<void> setModel(String provider, String model) async {
    final r = await client
        .request('session/setModel', {'provider': provider, 'model': model});
    this.provider = '${r['provider']}';
    this.model = '${r['model']}';
  }

  Future<void> setProjects(List<String> p) async {
    final r = await client.request('session/setProjects', {'projects': p});
    projects = ((r['projects'] as List?) ?? const []).map((e) => '$e').toList();
  }

  Future<void> close() => client.close();
}
