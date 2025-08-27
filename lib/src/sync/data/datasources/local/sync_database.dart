import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/sync/data/datasources/local/create_start_database.dart';

/// Database handler for Shepherd sync operations.
/// Handles import/export of activities and YAML data.
class SyncDatabase {
  final String projectPath;
  Database? _database;

  SyncDatabase(this.projectPath);

  /// Returns the SQLite database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    // MIGRATION: Ensure the github_username column exists in the persons table
    await ensureCoreTables(_database!);
    try {
      final columns = await _database!.rawQuery("PRAGMA table_info(persons)");
      final hasGithub = columns.any((col) => col['name'] == 'github_username');
      if (!hasGithub) {
        await _database!
            .execute('ALTER TABLE persons ADD COLUMN github_username TEXT');
      }
    } catch (e) {
      print('[Shepherd] Warning: Could not check or migrate persons table: $e');
    }
    return _database!;
  }

  /// Initializes the SQLite database and creates tables if needed.
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
          // ...existing table creation code...
          await db.execute('''
            CREATE TABLE pending_prs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              repository TEXT NOT NULL,
              source_branch TEXT NOT NULL,
              target_branch TEXT NOT NULL,
              title TEXT NOT NULL,
              description TEXT,
              work_items TEXT,
              reviewers TEXT,
              created_at TEXT NOT NULL
            )
          ''');
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
          await db.execute('''
            CREATE TABLE persons (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              first_name TEXT NOT NULL,
              last_name TEXT NOT NULL,
              email TEXT NOT NULL,
              type TEXT NOT NULL,
              github_username TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE domain_owners (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              domain_name TEXT NOT NULL,
              project_path TEXT NOT NULL,
              person_id INTEGER NOT NULL,
              FOREIGN KEY(person_id) REFERENCES persons(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE domains (
              name TEXT PRIMARY KEY
            )
          ''');
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

  /// Imports user stories and tasks from shepherd_activity.yaml into the database.
  Future<void> importActivitiesFromYaml([
    String activityFilePath = '.shepherd/shepherd_activity.yaml',
  ]) async {
    final db = await database;
    final file = File(activityFilePath);
    if (!await file.exists()) return;
    final content = await file.readAsString();
    if (content.trim().isEmpty) return;
    final loaded = loadYaml(content);
    if (loaded is! List) return;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stories (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        domains TEXT,
        status TEXT,
        created_by TEXT,
        created_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        story_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT,
        assignee TEXT,
        created_at TEXT,
        FOREIGN KEY(story_id) REFERENCES stories(id)
      )
    ''');
    await db.delete('tasks');
    await db.delete('stories');
    for (final entry in loaded) {
      if (entry is! Map) continue;
      if (entry['type'] == 'user_story') {
        await db.insert('stories', {
          'id': entry['id'],
          'title': entry['title'],
          'description': entry['description'] ?? '',
          'domains': (entry['domains'] as List?)?.join(',') ?? '',
          'status': entry['status'] ?? 'open',
          'created_by': entry['created_by'] ?? '',
          'created_at': entry['created_at'] ?? '',
        });
        final tasks = entry['tasks'] as List?;
        if (tasks != null) {
          for (final task in tasks) {
            if (task is! Map) continue;
            await db.insert('tasks', {
              'id': task['id'],
              'story_id': entry['id'],
              'title': task['title'],
              'description': task['description'] ?? '',
              'status': task['status'] ?? 'open',
              'assignee': task['assignee'] ?? '',
              'created_at': task['created_at'] ?? '',
            });
          }
        }
      }
    }
  }

  /// Imports data from a YAML (in shepherd export-yaml format)
  Future<void> importFromYaml(dynamic yaml) async {
    final db = await database;
    // Garante que as tabelas principais existem
    await ensureCoreTables(db);
    await db.delete('domain_owners');
    await db.delete('persons');
    await db.delete('domains');
    final domains = yaml['domains'] as List?;
    if (domains == null) return;
    for (final domain in domains) {
      final domainName = domain['name'] as String;
      await db.insert('domains', {'name': domainName});
      await db.insert(
        'domain_health',
        {
          'domain_name': domainName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'health_score': 0.0,
          'commits_since_last_tag': 0,
          'days_since_last_tag': 0,
          'warnings': '',
          'project_path': projectPath,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final owners = domain['owners'] as List?;
      if (owners != null) {
        for (final owner in owners) {
          final person = {
            'first_name': owner['first_name'],
            'last_name': owner['last_name'],
            'email': owner['email'],
            'type': owner['type'],
            'github_username': owner['github_username'],
          };
          final personId = await db.insert('persons', person);
          await db.insert('domain_owners', {
            'domain_name': domainName,
            'project_path': projectPath,
            'person_id': personId,
          });
        }
      }
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
