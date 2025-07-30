import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ConfigDatabase {
  /// Closes the database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  final String projectPath;
  Database? _database;

  ConfigDatabase(this.projectPath);

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
    return await databaseFactoryFfi.openDatabase(dbPath);
  }

  Future<void> updatePersonGithubUsername(
      int personId, String githubUsername) async {
    final db = await database;
    await db.update(
      'persons',
      {'github_username': githubUsername},
      where: 'id = ?',
      whereArgs: [personId],
    );
  }

  Future<int> insertPerson({
    required String firstName,
    required String lastName,
    required String email,
    required String type,
    String? githubUsername,
  }) async {
    final db = await database;
    return await db.insert('persons', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'type': type,
      'github_username': githubUsername,
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
}
