import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shepherd/src/domain/entities/domain_health_entity.dart';

/// Database handler for the Shepherd project.
/// Manages domain health, persons, owners, and analysis logs using SQLite.
class ShepherdDatabase {
  final String projectPath;
  Database? _database;

  /// Creates a new [ShepherdDatabase] for the given project path.
  ShepherdDatabase(this.projectPath);

  /// Returns the SQLite database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Initializes the SQLite database and creates tables if needed.
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

  /// Deletes a domain and its health data from the database.
  Future<void> deleteDomain(String domainName) async {
    final db = await database;
    await db.delete(
      'domain_health',
      where: 'domain_name = ? AND project_path = ?',
      whereArgs: [domainName, projectPath],
    );
  }

  /// Returns all domain health entities for the current project.
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

  /// Inserts a new person into the database and returns their ID.
  Future<int> insertPerson(
      {required String firstName,
      required String lastName,
      required String type}) async {
    final db = await database;
    return await db.insert('persons', {
      'first_name': firstName,
      'last_name': lastName,
      'type': type,
    });
  }

  /// Returns all persons registered in the database.
  Future<List<Map<String, dynamic>>> getAllPersons() async {
    final db = await database;
    return await db.query('persons', orderBy: 'first_name, last_name');
  }

  /// Returns the person with the given ID, or null if not found.
  Future<Map<String, dynamic>?> getPersonById(int id) async {
    final db = await database;
    final result = await db.query('persons', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Inserts or updates a domain and its owners in the database.
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

  /// Inserts a new analysis log entry into the database.
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

  /// Returns the last 10 health history records for the given domain.
  Future<List<Map<String, dynamic>>> getDomainHealthHistory(
      String domainName) async {
    final db = await database;
    return await db.query(
      'domain_health',
      where: 'domain_name = ? AND project_path = ?',
      whereArgs: [domainName, projectPath],
      orderBy: 'timestamp DESC',
      limit: 10,
    );
  }

  /// Closes the database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
