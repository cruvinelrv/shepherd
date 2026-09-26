import 'dart:io';
import 'package:path/path.dart' as p;

/// Result of local file context extraction.
class LocalFileContextResult {
  final String enrichedPrompt;
  final List<String> resolvedFiles;
  final List<String> missingFiles;

  const LocalFileContextResult({
    required this.enrichedPrompt,
    required this.resolvedFiles,
    required this.missingFiles,
  });
}

/// Service that resolves file mentions (`@path/to/file`) and explicit `--file` flags,
/// reading local files into the AI prompt context.
class AiLocalContextService {
  /// Scans [prompt] for `@path/to/file` mentions and combines them with [explicitFiles].
  /// Reads files from disk and appends formatted code blocks to the prompt.
  static LocalFileContextResult resolveLocalFiles({
    required String prompt,
    List<String> explicitFiles = const [],
    String? basePath,
  }) {
    final root = basePath ?? Directory.current.path;
    final filePaths = <String>{...explicitFiles};

    // Regex matching @path/to/file.ext or special files like Dockerfile
    final mentionPattern = RegExp(r'@([\w\-./\\]+\.[a-zA-Z0-9_\-]+|Dockerfile|Makefile)');
    for (final match in mentionPattern.allMatches(prompt)) {
      final matched = match.group(1);
      if (matched != null && matched.isNotEmpty) {
        filePaths.add(matched);
      }
    }

    final resolved = <String>[];
    final missing = <String>[];
    final fileContextBuffer = StringBuffer();

    for (final relPath in filePaths) {
      final cleanPath = relPath.replaceAll('\\', '/');
      final fullPath = p.isAbsolute(cleanPath) ? cleanPath : p.join(root, cleanPath);
      final file = File(fullPath);

      if (file.existsSync()) {
        try {
          final content = file.readAsStringSync();
          resolved.add(cleanPath);
          fileContextBuffer.writeln('\n--- Arquivo Local: $cleanPath ---');
          fileContextBuffer.writeln(content);
          fileContextBuffer.writeln('----------------------------------');
        } catch (_) {
          missing.add(cleanPath);
        }
      } else {
        missing.add(cleanPath);
      }
    }

    var finalPrompt = prompt;
    if (fileContextBuffer.isNotEmpty) {
      finalPrompt = '${fileContextBuffer.toString().trim()}\n\n$prompt';
    }

    return LocalFileContextResult(
      enrichedPrompt: finalPrompt,
      resolvedFiles: resolved,
      missingFiles: missing,
    );
  }
}
