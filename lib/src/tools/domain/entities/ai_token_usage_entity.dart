class AiTokenUsageEntity {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final bool isLocal;
  final bool isEstimated;

  const AiTokenUsageEntity({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.isLocal,
    this.isEstimated = false,
  });

  /// Identifies the consumption category (Local / Free vs API / Paid).
  String get typeLabel => isLocal ? 'Local / Gratuito' : 'API / Pago';

  String formatSummary() {
    final prefix = isEstimated ? '~' : '';
    return '$prefix$totalTokens ($typeLabel)';
  }

  String formatDetailed() {
    final prefix = isEstimated ? '~' : '';
    return '$prefix$totalTokens [${promptTokens}p + ${completionTokens}c] ($typeLabel)';
  }
}
