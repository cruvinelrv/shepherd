import 'dart:io';
import 'package:path/path.dart' as p;
import 'workspace_manifest_service.dart';

class ScanFileTarget {
  final String projectName;
  final String projectPath;
  final String relativePath;
  final File file;

  const ScanFileTarget({
    required this.projectName,
    required this.projectPath,
    required this.relativePath,
    required this.file,
  });
}

class TextChunk {
  final int index;
  final String content;
  final int tokenCount;

  const TextChunk({
    required this.index,
    required this.content,
    required this.tokenCount,
  });
}

/// Serviço que escaneia projetos e workspaces do Shepherd, dividindo arquivos de código em chunks semânticos.
class AiWorkspaceScannerService {
  final String basePath;

  AiWorkspaceScannerService([String? path]) : basePath = path ?? Directory.current.path;

  static const supportedExtensions = {
    '.dart',
    '.yaml',
    '.json',
    '.md',
    '.js',
    '.ts',
    '.tsx',
    '.jsx',
    '.py',
    '.go',
    '.rs',
    '.html',
    '.css',
    '.sql',
    '.sh',
    '.swift',
    '.kt',
  };

  static const excludedDirs = {
    '.git',
    '.dart_tool',
    '.shepherd',
    'build',
    'node_modules',
    '.idea',
    '.vscode',
    'dist',
    '.gradle',
    'Pods',
    'coverage',
    '.fvm',
  };

  static const excludedFilePatterns = {
    '.g.dart',
    '.freezed.dart',
    '.lock',
    '.min.js',
    '.min.css',
  };

  /// Descobre os projetos e arquivos a serem indexados.
  List<ScanFileTarget> discoverFiles({String? specificProject}) {
    final targets = <ScanFileTarget>[];
    final manifest = WorkspaceManifest.tryLoad();

    if (manifest != null && manifest.projects.isNotEmpty) {
      for (final proj in manifest.projects) {
        if (specificProject != null &&
            proj.name.toLowerCase() != specificProject.toLowerCase() &&
            proj.id.toLowerCase() != specificProject.toLowerCase()) {
          continue;
        }

        final projDir = Directory(p.isAbsolute(proj.path) ? proj.path : p.join(basePath, proj.path));
        if (projDir.existsSync()) {
          _scanDirectory(projDir, proj.name, projDir.path, targets);
        }
      }
    } else {
      // Standalone ou projeto único
      final projName = manifest?.name ?? p.basename(basePath);
      final currentDir = Directory(basePath);
      _scanDirectory(currentDir, projName, basePath, targets);
    }

    return targets;
  }

  void _scanDirectory(
    Directory dir,
    String projectName,
    String projectRoot,
    List<ScanFileTarget> outTargets,
  ) {
    try {
      final entries = dir.listSync(followLinks: false);
      for (final entry in entries) {
        final name = p.basename(entry.path);
        if (entry is Directory) {
          if (excludedDirs.contains(name) || name.startsWith('.')) continue;
          _scanDirectory(entry, projectName, projectRoot, outTargets);
        } else if (entry is File) {
          if (_isIndexableFile(name)) {
            final relPath = p.relative(entry.path, from: projectRoot).replaceAll('\\', '/');
            outTargets.add(ScanFileTarget(
              projectName: projectName,
              projectPath: projectRoot,
              relativePath: relPath,
              file: entry,
            ));
          }
        }
      }
    } catch (_) {}
  }

  bool _isIndexableFile(String filename) {
    for (final pattern in excludedFilePatterns) {
      if (filename.endsWith(pattern)) return false;
    }
    final ext = p.extension(filename).toLowerCase();
    return supportedExtensions.contains(ext);
  }

  /// Divide o conteúdo de um arquivo em chunks com sobreposição para manter o contexto semântico.
  List<TextChunk> chunkFile(String content, String relativePath, {int maxChunkChars = 1000, int overlapChars = 150}) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return [];

    if (trimmed.length <= maxChunkChars) {
      final header = '// File: $relativePath\n';
      final text = '$header$trimmed';
      return [
        TextChunk(
          index: 0,
          content: text,
          tokenCount: (text.length / 4).ceil(),
        ),
      ];
    }

    final chunks = <TextChunk>[];
    final lines = trimmed.split('\n');
    final currentBuffer = StringBuffer();
    var chunkIndex = 0;

    for (final line in lines) {
      if (currentBuffer.length + line.length > maxChunkChars && currentBuffer.isNotEmpty) {
        final rawText = currentBuffer.toString().trim();
        final text = '// File: $relativePath (part ${chunkIndex + 1})\n$rawText';
        chunks.add(TextChunk(
          index: chunkIndex++,
          content: text,
          tokenCount: (text.length / 4).ceil(),
        ));

        // Preserva as últimas linhas para sobreposição
        final bufferLines = rawText.split('\n');
        currentBuffer.clear();
        final overlapLines = bufferLines.length > 5 ? bufferLines.sublist(bufferLines.length - 4) : bufferLines;
        for (final oLine in overlapLines) {
          currentBuffer.writeln(oLine);
        }
      }
      currentBuffer.writeln(line);
    }

    if (currentBuffer.isNotEmpty) {
      final rawText = currentBuffer.toString().trim();
      if (rawText.isNotEmpty) {
        final text = '// File: $relativePath (part ${chunkIndex + 1})\n$rawText';
        chunks.add(TextChunk(
          index: chunkIndex,
          content: text,
          tokenCount: (text.length / 4).ceil(),
        ));
      }
    }

    return chunks;
  }
}
