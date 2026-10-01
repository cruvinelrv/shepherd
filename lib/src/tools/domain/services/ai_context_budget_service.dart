import '../../data/models/ai_vector_chunk_model.dart';

/// Service responsible for enforcing strict token budgets and chat history windowing
/// to prevent excessive credit consumption in cloud APIs.
class AiContextBudgetService {
  /// Maximum character limit injected by RAG for cloud providers (~600 tokens).
  static const int defaultCloudRagCharLimit = 2400;

  /// Maximum character limit injected by RAG for local providers (~1500 tokens).
  static const int defaultLocalRagCharLimit = 6000;

  /// Maximum lines of code preserved in older assistant message blocks.
  static const int maxHistoryCodeBlockLines = 6;

  /// Compacts chat history by collapsing large code blocks in previous turns.
  static List<Map<String, String>> compactHistory(
    List<Map<String, String>> history, {
    required bool isLocal,
    int maxTurns = 5,
  }) {
    if (history.isEmpty) return [];

    final recent = history.length > maxTurns
        ? history.sublist(history.length - maxTurns)
        : List<Map<String, String>>.from(history);

    final compacted = <Map<String, String>>[];
    for (var i = 0; i < recent.length; i++) {
      final item = recent[i];
      final role = item['role'] ?? 'user';
      var content = item['content'] ?? '';

      // Only collapse code in previous assistant turns (keep the latest turn intact)
      final isLastTurn = i == recent.length - 1;
      if (role == 'assistant' && !isLastTurn && !isLocal) {
        content = _collapseCodeBlocks(content);
      }

      compacted.add({'role': role, 'content': content});
    }

    return compacted;
  }

  /// Collapses long code blocks (```...```) replacing them with a concise summary.
  static String _collapseCodeBlocks(String text) {
    final codeBlockRegex = RegExp(r'```([a-zA-Z0-9_\-\.]*)\n([\s\S]*?)```');
    return text.replaceAllMapped(codeBlockRegex, (match) {
      final lang = match.group(1) ?? '';
      final code = match.group(2) ?? '';
      final lines = code.split('\n');

      if (lines.length <= maxHistoryCodeBlockLines) {
        return match.group(0)!;
      }

      final preview = lines.take(2).join('\n');
      return '```$lang\n$preview\n// [${lines.length - 2} lines of code collapsed to save context tokens]\n```';
    });
  }

  /// Formats and applies strict character/token budget to RAG matches.
  static String formatBudgetedRagContext(
    List<AiRagMatchModel> matches, {
    required bool isLocal,
    int? maxCharacters,
  }) {
    if (matches.isEmpty) return '';

    final limit = maxCharacters ??
        (isLocal ? defaultLocalRagCharLimit : defaultCloudRagCharLimit);

    final buffer = StringBuffer();
    buffer.writeln('--- Workspace Context Retrieved via RAG ---');

    var currentLength = buffer.length;
    var includedCount = 0;

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final percent = (match.score * 100).toStringAsFixed(0);
      final header = '[$i] ${match.chunk.filePath} (Similarity: $percent% | Project: ${match.chunk.projectName})\n```\n';
      const footer = '\n```\n\n';

      final available = limit - currentLength - header.length - footer.length;
      if (available <= 80 && includedCount > 0) {
        break; // Budget exhausted
      }

      final chunkContent = match.chunk.content;
      String contentToAdd;
      if (chunkContent.length <= available) {
        contentToAdd = chunkContent;
      } else {
        // Truncate chunk respecting the remaining budget
        final safeCut = available.clamp(0, chunkContent.length);
        contentToAdd = '${chunkContent.substring(0, safeCut)}\n// [Remaining snippet truncated to save context tokens]';
      }

      buffer.write(header);
      buffer.write(contentToAdd);
      buffer.write(footer);

      currentLength += header.length + contentToAdd.length + footer.length;
      includedCount++;

      if (currentLength >= limit) break;
    }

    return buffer.toString().trim();
  }
}
