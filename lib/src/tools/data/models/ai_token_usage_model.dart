import '../../domain/entities/ai_token_usage_entity.dart';

class AiTokenUsageModel extends AiTokenUsageEntity {
  const AiTokenUsageModel({
    required super.promptTokens,
    required super.completionTokens,
    required super.totalTokens,
    required super.isLocal,
    super.isEstimated = false,
  });

  /// Estimates token count based on text character length (~4 characters per token).
  factory AiTokenUsageModel.estimate({
    required String prompt,
    required String completion,
    required bool isLocal,
  }) {
    final pTokens = (prompt.length / 4).ceil();
    final cTokens = (completion.length / 4).ceil();
    return AiTokenUsageModel(
      promptTokens: pTokens > 0 ? pTokens : 1,
      completionTokens: cTokens > 0 ? cTokens : 1,
      totalTokens: (pTokens > 0 ? pTokens : 1) + (cTokens > 0 ? cTokens : 1),
      isLocal: isLocal,
      isEstimated: true,
    );
  }

  factory AiTokenUsageModel.fromMap(
    Map<dynamic, dynamic> map, {
    required bool isLocal,
  }) {
    final prompt = map['prompt_tokens'] as int? ??
        map['prompt_eval_count'] as int? ??
        map['input_tokens'] as int? ??
        0;
    final completion = map['completion_tokens'] as int? ??
        map['eval_count'] as int? ??
        map['output_tokens'] as int? ??
        0;
    final total = map['total_tokens'] as int? ?? (prompt + completion);
    final isEstimated = map['is_estimated'] as bool? ?? false;

    return AiTokenUsageModel(
      promptTokens: prompt,
      completionTokens: completion,
      totalTokens: total > 0 ? total : (prompt + completion),
      isLocal: isLocal,
      isEstimated: isEstimated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_tokens': totalTokens,
      'is_local': isLocal,
      'is_estimated': isEstimated,
      'type_label': typeLabel,
    };
  }
}
