/// Entity representing the response returned by the Shepherd Platform AI Gateway.
class AiGatewayResponseEntity {
  final String? taskId;
  final String mode;
  final String status;
  final String? text;
  final List<String> steps;
  final String? modelUsed;
  final String? error;

  const AiGatewayResponseEntity({
    this.taskId,
    required this.mode,
    required this.status,
    this.text,
    this.steps = const [],
    this.modelUsed,
    this.error,
  });

  bool get isSuccessful => status != 'error' && error == null;
  bool get isAwaitingPlanApproval => status == 'awaiting_plan_approval';
}
