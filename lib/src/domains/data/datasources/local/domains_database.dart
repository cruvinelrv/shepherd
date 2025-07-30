import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shepherd/src/domains/domain/entities/domain_health_entity.dart';

class DomainsDatabase {
  /// Insere um log de análise no banco de dados.
  Future<void> insertAnalysisLog({
    required int durationMs,
    required String status,
    required int totalDomains,
    required int unhealthyDomains,
    required String warnings,
  }) async {
    final db = await database;
    await db.insert('analysis_log', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'duration_ms': durationMs,
      'status': status,
      'total_domains': totalDomains,
      'unhealthy_domains': unhealthyDomains,
      'warnings': warnings,
      'project_path': projectPath,
    });
  }

  /// Fecha a conexão com o banco de dados, se aberta.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  final String projectPath;
  Database? _database;

  DomainsDatabase(this.projectPath);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final shepherdDir = Directory(join(projectPath, '.shepherd'));
    if (!await shepherdDir.exists()) {
      await shepherdDir.create(recursive: true);
    }
    final dbPath = join(shepherdDir.path, 'shepherd.db');
    sqfliteFfiInit();
    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS domain_health (
              domain_name TEXT NOT NULL,
              timestamp INTEGER,
              health_score REAL,
              commits_since_last_tag INTEGER,
              days_since_last_tag INTEGER,
              warnings TEXT,
              project_path TEXT NOT NULL,
              PRIMARY KEY(domain_name, project_path)
            );
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS domain_owners (
              domain_name TEXT NOT NULL,
              project_path TEXT NOT NULL,
              person_id INTEGER NOT NULL,
              PRIMARY KEY(domain_name, project_path, person_id)
            );
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS persons (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              first_name TEXT,
              last_name TEXT,
              email TEXT,
              type TEXT,
              github_username TEXT
            );
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS analysis_log (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp INTEGER,
              duration_ms INTEGER,
              status TEXT,
              total_domains INTEGER,
              unhealthy_domains INTEGER,
              warnings TEXT,
              project_path TEXT
            );
          ''');
        },
      ),
    );
  }

  Future<List<DomainHealthEntity>> getAllDomainHealths() async {
    final db = await database;
    final result = await db.query(
      'domain_health',
      where: 'project_path = ?',
      whereArgs: [projectPath],
      orderBy: 'domain_name ASC',
    );
    return result.map((row) {
      return DomainHealthEntity(
        domainName: row['domain_name'] as String,
        healthScore: (row['health_score'] as num).toDouble(),
        commitsSinceLastTag: row['commits_since_last_tag'] as int? ?? 0,
        daysSinceLastTag: row['days_since_last_tag'] as int? ?? 0,
        warnings: (row['warnings'] as String?)?.isNotEmpty == true
            ? (row['warnings'] as String).split(';')
            : <String>[],
        ownerCodes: <String>[],
      );
    }).toList();
  }

  Future<void> insertDomain({
    required String domainName,
    required double score,
    required int commits,
    required int days,
    required String warnings,
    required List<int> personIds,
    required String projectPath,
  }) async {
    final db = await database;
    await db.insert(
      'domain_health',
      {
        'domain_name': domainName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'health_score': score,
        'commits_since_last_tag': commits,
        'days_since_last_tag': days,
        'warnings': warnings,
        'project_path': projectPath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.delete('domain_owners',
        where: 'domain_name = ? AND project_path = ?',
        whereArgs: [domainName, projectPath]);
    for (final personId in personIds) {
      await db.insert('domain_owners', {
        'domain_name': domainName,
        'project_path': projectPath,
        'person_id': personId,
      });
    }
  }

  Future<void> deleteDomain(String domainName) async {
    final db = await database;
    await db.delete(
      'domain_health',
      where: 'domain_name = ? AND project_path = ?',
      whereArgs: [domainName, projectPath],
    );
  }

  Future<List<Map<String, dynamic>>> getOwnersForDomain(
      String domainName) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.* FROM domain_owners o
      JOIN persons p ON o.person_id = p.id
      WHERE o.domain_name = ? AND o.project_path = ?
    ''', [domainName, projectPath]);
  }
}
