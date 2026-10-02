import 'dart:convert';

/// Wire protocol of `shepherd ai --jsonl`: one JSON object per line on
/// stdin (requests) and stdout (events). Anything human-readable goes to
/// stderr so stdout stays machine-parseable.
const aiJsonlProtocolVersion = 1;

/// An event the CLI sends to its host (e.g. Shepherd Studio).
class AiEvent {
  final String type;
  final Map<String, dynamic> data;
  const AiEvent(this.type, [this.data = const {}]);

  /// First event: the effective settings after config/flag resolution.
  factory AiEvent.ready({
    required String provider,
    required String model,
    required String mode,
    required List<String> projects,
  }) =>
      AiEvent('ready', {
        'protocol': aiJsonlProtocolVersion,
        'provider': provider,
        'model': model,
        'mode': mode,
        'projects': projects,
      });

  factory AiEvent.textDelta(String text) => AiEvent('text_delta', {'text': text});
  factory AiEvent.reasoningDelta(String text) =>
      AiEvent('reasoning_delta', {'text': text});

  /// The model began writing [path] (relative to the workspace root).
  factory AiEvent.fileStarted(String path) => AiEvent('file_started', {'path': path});

  /// A complete file the user must approve with a `confirm` request.
  factory AiEvent.fileProposal({
    required String id,
    required String path,
    required String content,
    required bool isNew,
  }) =>
      AiEvent('file_proposal',
          {'id': id, 'path': path, 'content': content, 'is_new': isNew});

  /// A proposal dropped because it is outside the allowed projects/root.
  factory AiEvent.fileBlocked(String path, String reason) =>
      AiEvent('file_blocked', {'path': path, 'reason': reason});

  factory AiEvent.fileResult({
    required String id,
    required String path,
    required bool applied,
  }) =>
      AiEvent('file_result', {'id': id, 'path': path, 'applied': applied});

  factory AiEvent.usage({
    required int promptTokens,
    required int completionTokens,
    required bool isLocal,
  }) =>
      AiEvent('usage', {
        'prompt_tokens': promptTokens,
        'completion_tokens': completionTokens,
        'is_local': isLocal,
      });

  factory AiEvent.done() => const AiEvent('done');

  /// [code]: not_configured | ollama_offline | invalid_key | busy | bad_request | unknown
  factory AiEvent.error(String code, String message) =>
      AiEvent('error', {'code': code, 'message': message});

  Map<String, dynamic> toJson() => {'type': type, ...data};
  String encode() => jsonEncode(toJson());
}

/// A request from the host: `user_message`, `confirm`, `cancel`,
/// `set_model`, `set_mode` or `shutdown`.
class AiRequest {
  final String type;
  final Map<String, dynamic> data;
  const AiRequest(this.type, this.data);

  /// Null for blank lines, non-JSON, or JSON without a string `type`.
  static AiRequest? tryParse(String line) {
    if (line.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map && decoded['type'] is String) {
        return AiRequest(decoded['type'] as String, Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  String? str(String key) => data[key] is String ? data[key] as String : null;
  bool? flag(String key) => data[key] is bool ? data[key] as bool : null;
}
