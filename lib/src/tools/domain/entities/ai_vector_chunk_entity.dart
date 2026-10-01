/// Represents a code or documentation chunk indexed in the local vector database.
class AiVectorChunkEntity {
  final String id;
  final String projectName;
  final String filePath;
  final int chunkIndex;
  final String content;
  final List<double> embedding;
  final int lastModified;
  final int tokenCount;
  final String? contentHash;

  const AiVectorChunkEntity({
    required this.id,
    required this.projectName,
    required this.filePath,
    required this.chunkIndex,
    required this.content,
    required this.embedding,
    required this.lastModified,
    required this.tokenCount,
    this.contentHash,
  });
}

/// Represents a semantic similarity match from RAG search.
class AiRagMatchEntity {
  final AiVectorChunkEntity chunk;
  final double score;

  const AiRagMatchEntity({
    required this.chunk,
    required this.score,
  });
}

/// Statistics of the local vector database (.shepherd/vectors/embeddings.db).
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
