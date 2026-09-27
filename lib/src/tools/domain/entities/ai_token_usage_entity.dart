class AiTokenUsageEntity {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final bool isLocal;

  const AiTokenUsageEntity({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.isLocal,
  });

  /// Identifica a natureza do consumo (Local / Gratuito vs API / Pago)
  String get typeLabel => isLocal ? 'Local / Gratuito' : 'API / Pago';

  String formatSummary() {
    return '$totalTokens ($typeLabel)';
  }

  String formatDetailed() {
    return '$totalTokens [${promptTokens}p + ${completionTokens}c] ($typeLabel)';
  }
}
