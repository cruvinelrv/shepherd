import 'ai_file_action_entity.dart';

/// Entity representing the response returned by the Shepherd Platform AI Gateway.
class AiGatewayResponseEntity {
  final String? taskId;
  final String mode;
  final String status;
  final String? text;
  final List<String> steps;
  final String? modelUsed;
  final String? provider;
  final int? latencyMs;
  final int? tokensUsed;
  final List<AiFileActionEntity> fileActions;
  final String? error;

  const AiGatewayResponseEntity({
    this.taskId,
    required this.mode,
    required this.status,
    this.text,
    this.steps = const [],
    this.modelUsed,
    this.provider,
    this.latencyMs,
    this.tokensUsed,
    this.fileActions = const [],
    this.error,
  });

  bool get isSuccessful => status != 'error' && error == null;
  bool get isAwaitingPlanApproval => status == 'awaiting_plan_approval';
}
