// A stand-in for the engine: speaks the line-delimited JSON-RPC protocol just
// enough to test the client. Behaviour is driven by the question text.
import 'dart:convert';
import 'dart:io';

void send(Map<String, dynamic> m) =>
    stdout.writeln(jsonEncode({'jsonrpc': '2.0', ...m}));

Future<void> main() async {
  final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {
    final msg = jsonDecode(line) as Map<String, dynamic>;
    final id = msg['id'];
    final method = msg['method'];
    final params = (msg['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        send({
          'id': id,
          'result': {
            'protocolVersion': 2,
            'session': {
              'provider': 'ollama',
              'model': 'm',
              'mode': params['mode'] ?? 'fast',
              'projects': []
            },
            'capabilities': {'rag': true},
            'auth': {'required': true, 'offline': false}
          }
        });
      case 'session/send':
        final text = params['text'] as String;
        if (text == 'erro') {
          send({
            'id': id,
            'error': {
              'code': -32005,
              'message': 'modelo sumiu',
              'data': {'code': 'model_unavailable', 'model': 'm'}
            }
          });
        } else if (text == 'grande') {
          send({
            'method': 'session/textDelta',
            'params': {'requestId': id, 'text': 'x' * 200000}
          });
          send({
            'id': id,
            'result': {
              'stopReason': 'complete',
              'usage': {
                'promptTokens': 1,
                'completionTokens': 1,
                'isLocal': true
              }
            }
          });
        } else {
          send({
            'method': 'session/textDelta',
            'params': {'requestId': id, 'text': 'Olá'}
          });
          send({
            'method': 'session/textDelta',
            'params': {'requestId': id, 'text': ', $text'}
          });
          send({
            'id': id,
            'result': {
              'stopReason': 'complete',
              'usage': {
                'promptTokens': 10,
                'completionTokens': 4,
                'isLocal': true
              }
            }
          });
        }
      case 'shutdown':
        send({'id': id, 'result': null});
      case 'exit':
        exit(0);
    }
  }
}
