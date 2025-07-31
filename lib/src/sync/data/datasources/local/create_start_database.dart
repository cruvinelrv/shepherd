import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> ensureCoreTables(Database db) async {
  await db.execute('''CREATE TABLE IF NOT EXISTS persons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL,
    type TEXT NOT NULL,
    github_username TEXT
  )''');
  await db.execute('''CREATE TABLE IF NOT EXISTS domain_owners (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    domain_name TEXT NOT NULL,
    project_path TEXT NOT NULL,
    person_id INTEGER NOT NULL,
    FOREIGN KEY(person_id) REFERENCES persons(id)
  )''');
  await db.execute('''CREATE TABLE IF NOT EXISTS domains (
    name TEXT PRIMARY KEY
  )''');
  await db.execute('''CREATE TABLE IF NOT EXISTS domain_health (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    domain_name TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    health_score REAL NOT NULL,
    commits_since_last_tag INTEGER,
    days_since_last_tag INTEGER,
    warnings TEXT,
    project_path TEXT NOT NULL,
    UNIQUE(domain_name, project_path)
  )''');
  await db.execute('''CREATE TABLE IF NOT EXISTS analysis_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp INTEGER NOT NULL,
    project_path TEXT NOT NULL,
    duration_ms INTEGER,
    status TEXT,
    total_domains INTEGER,
    unhealthy_domains INTEGER,
    warnings TEXT
  )''');
}
