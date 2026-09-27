import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/ai_vector_chunk_model.dart';

/// Gerencia o banco vetorial local SQLite em `.shepherd/vectors/embeddings.db`.
class AiVectorDatabase {
  final String basePath;
  Database? _database;

  AiVectorDatabase([String? path]) : basePath = path ?? Directory.current.path;

  String get dbFilePath => p.join(basePath, '.shepherd', 'vectors', 'embeddings.db');

  bool get exists => File(dbFilePath).existsSync();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final vectorsDir = Directory(p.join(basePath, '.shepherd', 'vectors'));
    if (!await vectorsDir.exists()) {
      await vectorsDir.create(recursive: true);
    }

    sqfliteFfiInit();
    return await databaseFactoryFfi.openDatabase(
      dbFilePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS vector_chunks (
              id TEXT PRIMARY KEY,
              project_name TEXT NOT NULL,
              file_path TEXT NOT NULL,
              chunk_index INTEGER NOT NULL,
              content TEXT NOT NULL,
              embedding_json TEXT NOT NULL,
              last_modified INTEGER NOT NULL,
              token_count INTEGER NOT NULL
            );
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_chunks_project ON vector_chunks(project_name);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_chunks_file ON vector_chunks(file_path);',
          );
        },
      ),
    );
  }

  /// Insere ou substitui múltiplos chunks em lote (Batch).
  Future<void> upsertChunks(List<AiVectorChunkModel> chunks) async {
    if (chunks.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final chunk in chunks) {
      batch.insert(
        'vector_chunks',
        chunk.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Remove os chunks de um arquivo específico.
  Future<void> deleteChunksForFile(String projectName, String filePath) async {
    final db = await database;
    await db.delete(
      'vector_chunks',
      where: 'project_name = ? AND file_path = ?',
      whereArgs: [projectName, filePath],
    );
  }

  /// Remove todos os registros de um projeto.
  Future<void> clearProject(String projectName) async {
    final db = await database;
    await db.delete(
      'vector_chunks',
      where: 'project_name = ?',
      whereArgs: [projectName],
    );
  }

  /// Limpa todos os dados da base vetorial.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('vector_chunks');
  }

  /// Retorna um mapa de filePath -> lastModified para detecção de alterações incrementais.
  Future<Map<String, int>> getFileTimestamps([String? projectName]) async {
    final db = await database;
    String query = 'SELECT file_path, MAX(last_modified) as last_modified FROM vector_chunks';
    List<Object?> args = [];
    if (projectName != null && projectName.isNotEmpty) {
      query += ' WHERE project_name = ? GROUP BY file_path';
      args = [projectName];
    } else {
      query += ' GROUP BY file_path';
    }

    final rows = await db.rawQuery(query, args);
    final map = <String, int>{};
    for (final row in rows) {
      final path = row['file_path']?.toString();
      final ts = row['last_modified'] as int?;
      if (path != null && ts != null) {
        map[path] = ts;
      }
    }
    return map;
  }

  /// Busca os chunks mais semanticamente similares usando similaridade de cosseno.
  Future<List<AiRagMatchModel>> searchSimilar({
    required List<double> queryEmbedding,
    int topK = 5,
    double minScore = 0.30,
    String? projectName,
  }) async {
    if (queryEmbedding.isEmpty) return [];

    final db = await database;
    String query = 'SELECT * FROM vector_chunks';
    List<Object?> args = [];
    if (projectName != null && projectName.isNotEmpty) {
      query += ' WHERE project_name = ?';
      args = [projectName];
    }

    final rows = await db.rawQuery(query, args);
    if (rows.isEmpty) return [];

    final matches = <AiRagMatchModel>[];

    for (final row in rows) {
      final chunk = AiVectorChunkModel.fromMap(row);
      if (chunk.embedding.isEmpty) continue;

      final score = _cosineSimilarity(queryEmbedding, chunk.embedding);
      if (score >= minScore) {
        matches.add(AiRagMatchModel(chunk: chunk, score: score));
      }
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    if (matches.length > topK) {
      return matches.sublist(0, topK);
    }
    return matches;
  }

  /// Retorna as métricas e estatísticas gerais do banco de dados vetorial.
  Future<AiVectorStoreStatsModel> getStats() async {
    if (!exists) {
      return AiVectorStoreStatsModel(
        totalChunks: 0,
        totalFiles: 0,
        totalProjects: 0,
        totalTokens: 0,
        dbPath: dbFilePath,
        lastUpdated: null,
      );
    }

    final db = await database;
    final row = await db.rawQuery('''
      SELECT 
        COUNT(id) as total_chunks,
        COUNT(DISTINCT file_path) as total_files,
        COUNT(DISTINCT project_name) as total_projects,
        SUM(token_count) as total_tokens,
        MAX(last_modified) as last_modified
      FROM vector_chunks
    ''');

    if (row.isNotEmpty) {
      return AiVectorStoreStatsModel.fromMap(row.first, dbPath: dbFilePath);
    }

    return AiVectorStoreStatsModel(
      totalChunks: 0,
      totalFiles: 0,
      totalProjects: 0,
      totalTokens: 0,
      dbPath: dbFilePath,
      lastUpdated: null,
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  static double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }
}
