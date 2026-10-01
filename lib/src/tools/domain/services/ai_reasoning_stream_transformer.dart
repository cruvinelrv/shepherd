import 'dart:async';
import '../../data/models/ai_reasoning_chunk_model.dart';

/// Transforms an AI token/chunk stream by identifying and separating
/// reasoning/thinking blocks (`<think>...</think>` or `<thought>...</thought>`).
class AiReasoningStreamTransformer
    extends StreamTransformerBase<String, AiReasoningChunkModel> {
  const AiReasoningStreamTransformer();

  @override
  Stream<AiReasoningChunkModel> bind(Stream<String> stream) async* {
    var isThinking = false;
    var buffer = '';

    await for (final chunk in stream) {
      buffer += chunk;

      while (buffer.isNotEmpty) {
        if (!isThinking) {
          // Look for opening <think> or <thought>
          final openIndex = _findTagStart(buffer, const ['<think>', '<thought>']);
          if (openIndex == -1) {
            // Check if buffer ends with a potential tag prefix (e.g., "<", "<th", etc.)
            final potentialPrefixLen = _potentialTagPrefixLength(buffer, const ['<think>', '<thought>']);
            if (potentialPrefixLen > 0) {
              final emitLen = buffer.length - potentialPrefixLen;
              if (emitLen > 0) {
                yield AiReasoningChunkModel(
                  text: buffer.substring(0, emitLen),
                  isReasoning: false,
                );
                buffer = buffer.substring(emitLen);
              }
              break; // Wait for next chunk to disambiguate
            } else {
              yield AiReasoningChunkModel(text: buffer, isReasoning: false);
              buffer = '';
            }
          } else {
            // Emit content before <think>
            if (openIndex > 0) {
              yield AiReasoningChunkModel(
                text: buffer.substring(0, openIndex),
                isReasoning: false,
              );
            }
            final matchedTag = _matchedTag(buffer.substring(openIndex), const ['<think>', '<thought>']);
            buffer = buffer.substring(openIndex + (matchedTag?.length ?? 7));
            isThinking = true;
          }
        } else {
          // Look for closing </think> or </thought>
          final closeIndex = _findTagStart(buffer, const ['</think>', '</thought>']);
          if (closeIndex == -1) {
            final potentialPrefixLen = _potentialTagPrefixLength(buffer, const ['</think>', '</thought>']);
            if (potentialPrefixLen > 0) {
              final emitLen = buffer.length - potentialPrefixLen;
              if (emitLen > 0) {
                yield AiReasoningChunkModel(
                  text: buffer.substring(0, emitLen),
                  isReasoning: true,
                );
                buffer = buffer.substring(emitLen);
              }
              break; // Wait for next chunk
            } else {
              yield AiReasoningChunkModel(text: buffer, isReasoning: true);
              buffer = '';
            }
          } else {
            if (closeIndex > 0) {
              yield AiReasoningChunkModel(
                text: buffer.substring(0, closeIndex),
                isReasoning: true,
              );
            }
            final matchedTag = _matchedTag(buffer.substring(closeIndex), const ['</think>', '</thought>']);
            buffer = buffer.substring(closeIndex + (matchedTag?.length ?? 8));
            isThinking = false;
          }
        }
      }
    }

    if (buffer.isNotEmpty) {
      yield AiReasoningChunkModel(text: buffer, isReasoning: isThinking);
    }
  }

  static int _findTagStart(String text, List<String> tags) {
    var minIdx = -1;
    for (final tag in tags) {
      final idx = text.indexOf(tag);
      if (idx != -1 && (minIdx == -1 || idx < minIdx)) {
        minIdx = idx;
      }
    }
    return minIdx;
  }

  static String? _matchedTag(String text, List<String> tags) {
    for (final tag in tags) {
      if (text.startsWith(tag)) return tag;
    }
    return null;
  }

  static int _potentialTagPrefixLength(String text, List<String> tags) {
    for (var len = 1; len < 10 && len <= text.length; len++) {
      final suffix = text.substring(text.length - len);
      for (final tag in tags) {
        if (tag.startsWith(suffix) && suffix != tag) {
          return len;
        }
      }
    }
    return 0;
  }

  /// Removes `<think>...</think>` or `<thought>...</thought>` blocks from final text.
  static String stripThinking(String text) {
    var cleaned = text.replaceAll(RegExp(r'<think>[\s\S]*?<\/think>', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'<thought>[\s\S]*?<\/thought>', caseSensitive: false), '');
    return cleaned.trim();
  }
}
