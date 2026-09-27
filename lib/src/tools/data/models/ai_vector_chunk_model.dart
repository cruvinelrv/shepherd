import 'dart:convert';
import '../../domain/entities/ai_vector_chunk_entity.dart';

class AiVectorChunkModel extends AiVectorChunkEntity {
  const AiVectorChunkModel({
    required super.id,
    required super.projectName,
    required super.filePath,
    required super.chunkIndex,
    required super.content,
    required super.embedding,
    required super.lastModified,
    required super.tokenCount,
  });

  factory AiVectorChunkModel.fromMap(Map<String, dynamic> map) {
    List<double> parsedEmbedding = const [];
    final rawEmbedding = map['embedding_json'];
    if (rawEmbedding is String && rawEmbedding.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawEmbedding);
        if (decoded is List) {
          parsedEmbedding = decoded.map((e) => (e as num).toDouble()).toList();
        }
      } catch (_) {}
    } else if (map['embedding'] is List) {
      parsedEmbedding = (map['embedding'] as List).map((e) => (e as num).toDouble()).toList();
    }

    return AiVectorChunkModel(
      id: map['id']?.toString() ?? '',
      projectName: map['project_name']?.toString() ?? '',
      filePath: map['file_path']?.toString() ?? '',
      chunkIndex: map['chunk_index'] as int? ?? 0,
      content: map['content']?.toString() ?? '',
      embedding: parsedEmbedding,
      lastModified: map['last_modified'] as int? ?? 0,
      tokenCount: map['token_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_name': projectName,
      'file_path': filePath,
      'chunk_index': chunkIndex,
      'content': content,
      'embedding_json': jsonEncode(embedding),
      'last_modified': lastModified,
      'token_count': tokenCount,
    };
  }
}

class AiRagMatchModel extends AiRagMatchEntity {
  const AiRagMatchModel({
    required super.chunk,
    required super.score,
  });
}

class AiVectorStoreStatsModel extends AiVectorStoreStatsEntity {
  const AiVectorStoreStatsModel({
    required super.totalChunks,
    required super.totalFiles,
    required super.totalProjects,
    required super.totalTokens,
    required super.dbPath,
    super.lastUpdated,
  });

  factory AiVectorStoreStatsModel.fromMap(Map<String, dynamic> map, {required String dbPath}) {
    final lastModifiedTs = map['last_modified'] as int?;
    return AiVectorStoreStatsModel(
      totalChunks: map['total_chunks'] as int? ?? 0,
      totalFiles: map['total_files'] as int? ?? 0,
      totalProjects: map['total_projects'] as int? ?? 0,
      totalTokens: map['total_tokens'] as int? ?? 0,
      dbPath: dbPath,
      lastUpdated: lastModifiedTs != null && lastModifiedTs > 0
          ? DateTime.fromMillisecondsSinceEpoch(lastModifiedTs)
          : null,
    );
  }
}
