import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The engine answered a request with a JSON-RPC error.
class RpcException implements Exception {
  final int code;
  final String message;

  /// The stable string the host switches on (`error.data.code`), if any.
  final String? stableCode;
  final Map<String, dynamic> data;

  RpcException(this.code, this.message, this.data)
      : stableCode = data['code']?.toString();

  @override
  String toString() => message;
}

/// A message the engine sent on its own (no `id`).
class RpcNotification {
  final String method;
  final Map<String, dynamic> params;
  const RpcNotification(this.method, this.params);
}

/// Talks JSON-RPC 2.0 to a child process over stdin/stdout, one message per
/// line (the engine protocol, version 2). Lines may be any length: a whole file
/// travels in one message.
class RpcClient {
  final Process _process;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  final _notifications = StreamController<RpcNotification>.broadcast();
  var _nextId = 1;
  late final Future<int> exitCode;

  RpcClient._(this._process) {
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine, onDone: _onClosed);
    _process.stderr.transform(utf8.decoder).listen(stderr.write);
    exitCode = _process.exitCode;
  }

  static Future<RpcClient> start(String executable,
      {List<String> args = const [],
      String? workingDirectory,
      Map<String, String>? environment}) async {
    final process = await Process.start(executable, args,
        workingDirectory: workingDirectory, environment: environment);
    return RpcClient._(process);
  }

  Stream<RpcNotification> get notifications => _notifications.stream;

  void _onLine(String line) {
    if (line.trim().isEmpty) return;
    final Object? msg;
    try {
      msg = jsonDecode(line);
    } on FormatException {
      return;
    }
    if (msg is! Map<String, dynamic>) return;
    final id = msg['id'];
    if (id is int && msg['method'] == null) {
      _pending.remove(id)?.complete(msg);
    } else if (msg['method'] is String) {
      final params = msg['params'];
      _notifications.add(RpcNotification(msg['method'] as String,
          params is Map<String, dynamic> ? params : const {}));
    }
  }

  void _onClosed() {
    for (final c in _pending.values) {
      c.completeError(RpcException(
          -32000,
          'O motor de IA encerrou de forma inesperada.',
          const {'code': 'engine_exited'}));
    }
    _pending.clear();
    _notifications.close();
  }

  /// Sends a request and returns its `result`; throws [RpcException] on an error.
  /// [onId] receives the id as soon as it is chosen, to cancel the request later.
  Future<Map<String, dynamic>> request(String method,
      [Map<String, dynamic>? params, void Function(int id)? onId]) async {
    final id = _nextId++;
    final done = Completer<Map<String, dynamic>>();
    _pending[id] = done;
    onId?.call(id);
    _send({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params
    });
    final msg = await done.future;
    final error = msg['error'];
    if (error is Map<String, dynamic>) {
      final data = error['data'];
      throw RpcException(
          (error['code'] as num?)?.toInt() ?? -32000,
          '${error['message']}',
          data is Map<String, dynamic> ? data : const {});
    }
    final result = msg['result'];
    return result is Map<String, dynamic> ? result : const {};
  }

  void notify(String method, [Map<String, dynamic>? params]) => _send({
        'jsonrpc': '2.0',
        'method': method,
        if (params != null) 'params': params
      });

  void cancel(int requestId) => notify(r'$/cancelRequest', {'id': requestId});

  void _send(Map<String, dynamic> message) {
    try {
      _process.stdin.writeln(jsonEncode(message));
    } catch (_) {
      // the engine is gone; the pending requests are failed by _onClosed
    }
  }

  /// Asks the engine to stop and, if it does not, stops it.
  Future<void> close() async {
    try {
      await request('shutdown').timeout(const Duration(seconds: 2));
      notify('exit');
    } catch (_) {}
    try {
      await _process.stdin.close();
    } catch (_) {}
    await exitCode.timeout(const Duration(seconds: 3), onTimeout: () {
      _process.kill();
      return -1;
    });
  }
}
