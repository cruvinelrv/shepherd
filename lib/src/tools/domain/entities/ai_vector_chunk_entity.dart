/// Representa um fragmento de código ou documentação indexado no banco vetorial local.
class AiVectorChunkEntity {
  final String id;
  final String projectName;
  final String filePath;
  final int chunkIndex;
  final String content;
  final List<double> embedding;
  final int lastModified;
  final int tokenCount;

  const AiVectorChunkEntity({
    required this.id,
    required this.projectName,
    required this.filePath,
    required this.chunkIndex,
    required this.content,
    required this.embedding,
    required this.lastModified,
    required this.tokenCount,
  });
}

/// Representa um resultado de busca por similaridade semântica (RAG).
class AiRagMatchEntity {
  final AiVectorChunkEntity chunk;
  final double score;

  const AiRagMatchEntity({
    required this.chunk,
    required this.score,
  });
}

/// Estatísticas do banco de dados vetorial local (.shepherd/vectors/embeddings.db).
class AiVectorStoreStatsEntity {
  final int totalChunks;
  final int totalFiles;
  final int totalProjects;
  final int totalTokens;
  final String dbPath;
  final DateTime? lastUpdated;

  const AiVectorStoreStatsEntity({
    required this.totalChunks,
    required this.totalFiles,
    required this.totalProjects,
    required this.totalTokens,
    required this.dbPath,
    this.lastUpdated,
  });
}
