import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DeployDatabase {
  final String projectPath;
  Database? _database;

  DeployDatabase(this.projectPath);

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

  Future<void> insertPendingPr({
    required String repository,
    required String sourceBranch,
    required String targetBranch,
    required String title,
    String? description,
    String? workItems,
    String? reviewers,
    required String createdAt,
  }) async {
    final db = await database;
    await db.insert('pending_prs', {
      'repository': repository,
      'source_branch': sourceBranch,
      'target_branch': targetBranch,
      'title': title,
      'description': description,
      'work_items': workItems,
      'reviewers': reviewers,
      'created_at': createdAt,
    });
  }

  Future<List<Map<String, dynamic>>> getAllPendingPrs() async {
    final db = await database;
    return await db.query('pending_prs', orderBy: 'created_at ASC');
  }

  Future<void> deletePendingPr(int id) async {
    final db = await database;
    await db.delete('pending_prs', where: 'id = ?', whereArgs: [id]);
  }
}
