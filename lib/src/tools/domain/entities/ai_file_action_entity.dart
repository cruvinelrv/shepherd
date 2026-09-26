enum AiFileActionType { create, modify, delete }

/// Entity representing an AI proposed file action (creation, modification or deletion).
class AiFileActionEntity {
  final String path;
  final AiFileActionType actionType;
  final String? newContent;
  final String? originalContent;
  final String? diff;

  const AiFileActionEntity({
    required this.path,
    required this.actionType,
    this.newContent,
    this.originalContent,
    this.diff,
  });
}
