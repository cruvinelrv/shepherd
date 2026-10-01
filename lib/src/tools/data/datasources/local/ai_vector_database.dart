import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/ai_vector_chunk_model.dart';

/// Manages the local SQLite vector database at `.shepherd/vectors/embeddings.db`.
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
              content_hash TEXT,
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
        onOpen: (db) async {
          try {
            await db.execute('ALTER TABLE vector_chunks ADD COLUMN content_hash TEXT;');
          } catch (_) {
            // Column already exists
          }
        },
      ),
    );
  }

  /// Inserts or replaces multiple chunks in batch.
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

  /// Deletes chunks belonging to a specific file.
  Future<void> deleteChunksForFile(String projectName, String filePath) async {
    final db = await database;
    await db.delete(
      'vector_chunks',
      where: 'project_name = ? AND file_path = ?',
      whereArgs: [projectName, filePath],
    );
  }

  /// Deletes all chunks belonging to a project.
  Future<void> clearProject(String projectName) async {
    final db = await database;
    await db.delete(
      'vector_chunks',
      where: 'project_name = ?',
      whereArgs: [projectName],
    );
  }

  /// Clears all data from the vector database.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('vector_chunks');
  }

  /// Returns a map of filePath -> lastModified for incremental change detection.
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

  /// Returns a map of filePath -> contentHash for SHA-256 change detection.
  Future<Map<String, String>> getFileHashes([String? projectName]) async {
    final db = await database;
    String query = 'SELECT file_path, content_hash FROM vector_chunks WHERE content_hash IS NOT NULL';
    List<Object?> args = [];
    if (projectName != null && projectName.isNotEmpty) {
      query += ' AND project_name = ? GROUP BY file_path';
      args = [projectName];
    } else {
      query += ' GROUP BY file_path';
    }

    final rows = await db.rawQuery(query, args);
    final map = <String, String>{};
    for (final row in rows) {
      final path = row['file_path']?.toString();
      final hash = row['content_hash']?.toString();
      if (path != null && hash != null) {
        map[path] = hash;
      }
    }
    return map;
  }

  /// Deletes orphan files (files that no longer exist on disk).
  Future<int> deleteOrphanFiles(List<String> validFilePaths, [String? projectName]) async {
    final db = await database;
    final existingFiles = await db.rawQuery(
      projectName != null && projectName.isNotEmpty
          ? 'SELECT DISTINCT file_path FROM vector_chunks WHERE project_name = ?'
          : 'SELECT DISTINCT file_path FROM vector_chunks',
      projectName != null && projectName.isNotEmpty ? [projectName] : [],
    );

    final validSet = validFilePaths.toSet();
    var deleted = 0;
    for (final row in existingFiles) {
      final path = row['file_path']?.toString();
      if (path != null && !validSet.contains(path)) {
        await db.delete(
          'vector_chunks',
          where: projectName != null && projectName.isNotEmpty
              ? 'project_name = ? AND file_path = ?'
              : 'file_path = ?',
          whereArgs: projectName != null && projectName.isNotEmpty
              ? [projectName, path]
              : [path],
        );
        deleted++;
      }
    }
    return deleted;
  }

  /// Searches the most semantically similar chunks using cosine similarity.
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

  /// Returns overall metrics and statistics for the vector database.
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
