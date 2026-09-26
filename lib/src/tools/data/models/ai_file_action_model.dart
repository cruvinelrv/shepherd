import '../../domain/entities/ai_file_action_entity.dart';

/// Model representing an AI proposed file action with serialization.
class AiFileActionModel extends AiFileActionEntity {
  const AiFileActionModel({
    required super.path,
    required super.actionType,
    super.newContent,
    super.originalContent,
    super.diff,
  });

  factory AiFileActionModel.fromJson(Map<String, dynamic> json) {
    var type = AiFileActionType.modify;
    final typeStr = json['type']?.toString().toLowerCase();
    if (typeStr == 'create') {
      type = AiFileActionType.create;
    } else if (typeStr == 'delete') {
      type = AiFileActionType.delete;
    }

    return AiFileActionModel(
      path: json['path'] as String? ?? '',
      actionType: type,
      newContent: json['new_content'] as String?,
      originalContent: json['original_content'] as String?,
      diff: json['diff'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'type': actionType.name,
      if (newContent != null) 'new_content': newContent,
      if (originalContent != null) 'original_content': originalContent,
      if (diff != null) 'diff': diff,
    };
  }
}
