import '../../domain/entities/ai_gateway_response_entity.dart';
import 'ai_file_action_model.dart';

/// Model representing the response from the Shepherd Platform AI Gateway.
class AiGatewayResponseModel extends AiGatewayResponseEntity {
  const AiGatewayResponseModel({
    super.taskId,
    required super.mode,
    required super.status,
    super.text,
    super.steps,
    super.modelUsed,
    super.provider,
    super.latencyMs,
    super.tokensUsed,
    super.fileActions,
    super.error,
  });

  factory AiGatewayResponseModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedSteps = [];
    if (json['steps'] is List) {
      parsedSteps = (json['steps'] as List)
          .map((item) => item.toString())
          .toList();
    }

    List<AiFileActionModel> parsedActions = [];
    if (json['file_actions'] is List) {
      parsedActions = (json['file_actions'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => AiFileActionModel.fromJson(item))
          .toList();
    }

    return AiGatewayResponseModel(
      taskId: json['task_id'] as String?,
      mode: json['mode'] as String? ?? 'fast',
      status: json['status'] as String? ?? 'completed',
      text: json['text'] as String?,
      steps: parsedSteps,
      modelUsed: json['model_used'] as String?,
      provider: json['provider'] as String?,
      latencyMs: json['latency_ms'] as int?,
      tokensUsed: json['tokens_used'] as int?,
      fileActions: parsedActions,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (taskId != null) 'task_id': taskId,
      'mode': mode,
      'status': status,
      if (text != null) 'text': text,
      'steps': steps,
      if (modelUsed != null) 'model_used': modelUsed,
      if (provider != null) 'provider': provider,
      if (latencyMs != null) 'latency_ms': latencyMs,
      if (tokensUsed != null) 'tokens_used': tokensUsed,
      if (fileActions.isNotEmpty)
        'file_actions': fileActions
            .map((a) => (a is AiFileActionModel) ? a.toJson() : {
                  'path': a.path,
                  'type': a.actionType.name,
                  if (a.newContent != null) 'new_content': a.newContent,
                })
            .toList(),
      if (error != null) 'error': error,
    };
  }
}
