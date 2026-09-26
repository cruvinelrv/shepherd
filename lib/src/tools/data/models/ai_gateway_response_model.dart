import '../../domain/entities/ai_gateway_response_entity.dart';

/// Model representing the response from the Shepherd Platform AI Gateway.
class AiGatewayResponseModel extends AiGatewayResponseEntity {
  const AiGatewayResponseModel({
    super.taskId,
    required super.mode,
    required super.status,
    super.text,
    super.steps,
    super.modelUsed,
    super.error,
  });

  factory AiGatewayResponseModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedSteps = [];
    if (json['steps'] is List) {
      parsedSteps = (json['steps'] as List)
          .map((item) => item.toString())
          .toList();
    }

    return AiGatewayResponseModel(
      taskId: json['task_id'] as String?,
      mode: json['mode'] as String? ?? 'fast',
      status: json['status'] as String? ?? 'completed',
      text: json['text'] as String?,
      steps: parsedSteps,
      modelUsed: json['model_used'] as String?,
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
      if (error != null) 'error': error,
    };
  }
}
