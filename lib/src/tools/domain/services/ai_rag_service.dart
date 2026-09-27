import 'dart:convert';
import '../../data/datasources/local/ai_vector_database.dart';
import '../../data/models/ai_vector_chunk_model.dart';
import 'ai_embedding_service.dart';
import 'ai_workspace_scanner_service.dart';

class IndexingProgress {
  final int totalDiscoveredFiles;
  final int indexedFiles;
  final int skippedFiles;
  final int totalChunks;
  final int durationMs;

  const IndexingProgress({
    required this.totalDiscoveredFiles,
    required this.indexedFiles,
    required this.skippedFiles,
    required this.totalChunks,
    required this.durationMs,
  });
}

/// Serviço de coordenação do RAG Local: gerencia o índice vetorial em SQLite e a recuperação de contexto relevante.
class AiRagService {
  final AiVectorDatabase database;
  final AiEmbeddingService embeddingService;
  final AiWorkspaceScannerService scanner;

  AiRagService({
    AiVectorDatabase? database,
    AiEmbeddingService? embeddingService,
    AiWorkspaceScannerService? scanner,
    String? basePath,
  })  : database = database ?? AiVectorDatabase(basePath),
        embeddingService = embeddingService ?? AiEmbeddingService(),
        scanner = scanner ?? AiWorkspaceScannerService(basePath);

  bool get isIndexed => database.exists;

  Future<AiVectorStoreStatsModel> getStats() async {
    return await database.getStats();
  }

  /// Limpa todos os vetores indexados.
  Future<void> clearIndex() async {
    await database.clearAll();
  }

  /// Executa a indexação completa ou incremental dos arquivos do workspace.
  Future<IndexingProgress> indexWorkspace({
    bool force = false,
    String? specificProject,
    void Function(String message)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final targets = scanner.discoverFiles(specificProject: specificProject);
    onProgress?.call('🔍 Arquivos descobertos no workspace: ${targets.length}');

    if (force) {
      if (specificProject != null) {
        await database.clearProject(specificProject);
      } else {
        await database.clearAll();
      }
    }

    final existingTimestamps = force ? <String, int>{} : await database.getFileTimestamps(specificProject);

    var indexedFiles = 0;
    var skippedFiles = 0;
    var totalNewChunks = 0;

    for (final target in targets) {
      try {
        final lastModified = target.file.lastModifiedSync().millisecondsSinceEpoch;
        final knownTimestamp = existingTimestamps[target.relativePath];

        // Se o arquivo não mudou desde a última indexação, pula
        if (!force && knownTimestamp != null && lastModified <= knownTimestamp) {
          skippedFiles++;
          continue;
        }

        final content = target.file.readAsStringSync();
        final rawChunks = scanner.chunkFile(content, target.relativePath);
        if (rawChunks.isEmpty) {
          skippedFiles++;
          continue;
        }

        // Remove chunks antigos do arquivo antes de re-inserir
        if (knownTimestamp != null) {
          await database.deleteChunksForFile(target.projectName, target.relativePath);
        }

        final chunkModels = <AiVectorChunkModel>[];
        for (final raw in rawChunks) {
          final emb = await embeddingService.getEmbedding(raw.content);
          final chunkId = _generateChunkId(target.projectName, target.relativePath, raw.index);
          chunkModels.add(AiVectorChunkModel(
            id: chunkId,
            projectName: target.projectName,
            filePath: target.relativePath,
            chunkIndex: raw.index,
            content: raw.content,
            embedding: emb,
            lastModified: lastModified,
            tokenCount: raw.tokenCount,
          ));
        }

        await database.upsertChunks(chunkModels);
        indexedFiles++;
        totalNewChunks += chunkModels.length;

        onProgress?.call('⚡ [${indexedFiles + skippedFiles}/${targets.length}] Indexado: ${target.relativePath} (${chunkModels.length} chunks)');
      } catch (_) {
        skippedFiles++;
      }
    }

    stopwatch.stop();
    return IndexProgressResult(
      totalDiscoveredFiles: targets.length,
      indexedFiles: indexedFiles,
      skippedFiles: skippedFiles,
      totalChunks: totalNewChunks,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Recupera os chunks de código mais relevantes para a consulta do usuário.
  Future<List<AiRagMatchModel>> retrieveRelevantChunks({
    required String query,
    int topK = 4,
    double minScore = 0.28,
    String? projectName,
  }) async {
    if (!isIndexed) return [];

    try {
      final queryEmbedding = await embeddingService.getEmbedding(query);
      if (queryEmbedding.isEmpty) return [];

      return await database.searchSimilar(
        queryEmbedding: queryEmbedding,
        topK: topK,
        minScore: minScore,
        projectName: projectName,
      );
    } catch (_) {
      return [];
    }
  }

  /// Formata os fragmentos retornados pelo RAG para inclusão no prompt da IA.
  String formatRagContext(List<AiRagMatchModel> matches) {
    if (matches.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('--- Contexto Relevante do Workspace (Local RAG) ---');
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final percent = (match.score * 100).toStringAsFixed(1);
      buffer.writeln('[$i] ${match.chunk.filePath} (Similaridade: $percent% | Projeto: ${match.chunk.projectName})');
      buffer.writeln(match.chunk.content);
      buffer.writeln('---------------------------------------------------');
    }
    return buffer.toString().trim();
  }

  static String _generateChunkId(String projectName, String filePath, int chunkIndex) {
    final raw = '$projectName:$filePath:$chunkIndex';
    return base64Url.encode(utf8.encode(raw));
  }
}

class IndexProgressResult extends IndexingProgress {
  const IndexProgressResult({
    required super.totalDiscoveredFiles,
    required super.indexedFiles,
    required super.skippedFiles,
    required super.totalChunks,
    required super.durationMs,
  });
}
