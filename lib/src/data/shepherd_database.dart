import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shepherd/src/domain/entities/domain_health_entity.dart';

class ShepherdDatabase {
  final String projectPath;
  Database? _database;

  ShepherdDatabase(this.projectPath);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    //  Ensure the .shepherd directory exists
    final shepherdDir = Directory(join(projectPath, '.shepherd'));
    if (!await shepherdDir.exists()) {
      await shepherdDir.create(recursive: true);
    }

    final dbPath = join(shepherdDir.path, 'shepherd.db');

    sqfliteFfiInit(); // Initialize FFI for SQLite

    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // Table for domain health history
          await db.execute('''
            CREATE TABLE domain_health (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              domain_name TEXT NOT NULL,
              timestamp INTEGER NOT NULL,
              health_score REAL NOT NULL,
              commits_since_last_tag INTEGER,
              days_since_last_tag INTEGER,
              warnings TEXT,
              project_path TEXT NOT NULL,
              UNIQUE(domain_name, project_path)
            )
          ''');
          // Table for persons
          await db.execute('''
            CREATE TABLE persons (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              first_name TEXT NOT NULL,
              last_name TEXT NOT NULL,
              type TEXT NOT NULL
            )
          ''');
          // Table for domain owners (relates to persons)
          await db.execute('''
            CREATE TABLE domain_owners (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              domain_name TEXT NOT NULL,
              project_path TEXT NOT NULL,
              person_id INTEGER NOT NULL,
              FOREIGN KEY(person_id) REFERENCES persons(id)
            )
          ''');
          // Table for analysis logs (project-wide)
          await db.execute('''
            CREATE TABLE analysis_log (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp INTEGER NOT NULL,
              project_path TEXT NOT NULL,
              duration_ms INTEGER,
              status TEXT,
              total_domains INTEGER,
              unhealthy_domains INTEGER,
              warnings TEXT
            )
          ''');
        },
      ),
    );
  }

  Future<void> deleteDomain(String domainName) async {
    final db = await database;
    await db.delete(
      'domain_health',
      where: 'domain_name = ? AND project_path = ?',
      whereArgs: [domainName, projectPath],
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
        ownerCodes: <String>[], // Fill if you want to fetch the owners
      );
    }).toList();
  }

  Future<int> insertPerson(
      {required String firstName, required String lastName, required String type}) async {
    final db = await database;
    return await db.insert('persons', {
      'first_name': firstName,
      'last_name': lastName,
      'type': type,
    });
  }

  Future<List<Map<String, dynamic>>> getAllPersons() async {
    final db = await database;
    return await db.query('persons', orderBy: 'first_name, last_name');
  }

  Future<Map<String, dynamic>?> getPersonById(int id) async {
    final db = await database;
    final result = await db.query('persons', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return result.first;
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
    // Remove old owners and insert the new ones
    await db.delete('domain_owners',
        where: 'domain_name = ? AND project_path = ?', whereArgs: [domainName, projectPath]);
    for (final personId in personIds) {
      await db.insert('domain_owners', {
        'domain_name': domainName,
        'project_path': projectPath,
        'person_id': personId,
      });
    }
  }

  Future<void> insertAnalysisLog({
    required int durationMs,
    required String status,
    required int totalDomains,
    required int unhealthyDomains,
    required String warnings,
  }) async {
    final db = await database;
    await db.insert(
      'analysis_log',
      {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'project_path': projectPath,
        'duration_ms': durationMs,
        'status': status,
        'total_domains': totalDomains,
        'unhealthy_domains': unhealthyDomains,
        'warnings': warnings,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getDomainHealthHistory(String domainName) async {
    final db = await database;
    return await db.query(
      'domain_health',
      where: 'domain_name = ? AND project_path = ?',
      whereArgs: [domainName, projectPath],
      orderBy: 'timestamp DESC',
      limit: 10,
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
