import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:shepherd/src/domains/domain/entities/feature_toggle_entity.dart';

class FeatureToggleDatabase {
  Future<void> deleteFeatureToggleById(int id) async {
    final db = await database;
    await db.delete(
      'feature_toggles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  final String projectPath;
  Database? _database;

  FeatureToggleDatabase(this.projectPath);

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
    final db = await databaseFactoryFfi.openDatabase(dbPath);
    await db.execute('''
      CREATE TABLE IF NOT EXISTS feature_toggles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        enabled INTEGER NOT NULL,
        domain TEXT NOT NULL,
        description TEXT
      )
    ''');
    return db;
  }

  Future<int> insertFeatureToggle(FeatureToggleEntity toggle) async {
    final db = await database;
    // verify uniqueness of name
    final existing = await db.query('feature_toggles', where: 'name = ?', whereArgs: [toggle.name]);
    if (existing.isNotEmpty) {
      throw Exception('Já existe um Feature Toggle com o nome "${toggle.name}".');
    }
    return await db.insert('feature_toggles', {
      'name': toggle.name,
      'enabled': toggle.enabled ? 1 : 0,
      'domain': toggle.domain,
      'description': toggle.description,
    });
  }

  Future<void> updateFeatureToggleById(int id, FeatureToggleEntity updated) async {
    final db = await database;
    await db.update(
      'feature_toggles',
      {
        'name': updated.name,
        'enabled': updated.enabled ? 1 : 0,
        'domain': updated.domain,
        'description': updated.description,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<FeatureToggleEntity>> getAllFeatureToggles() async {
    final db = await database;
    final result = await db.query('feature_toggles');
    return result
        .map((row) => FeatureToggleEntity(
              id: row['id'] as int?,
              name: row['name'] as String,
              enabled: (row['enabled'] as int) == 1,
              domain: row['domain'] as String,
              description: row['description'] as String? ?? '',
            ))
        .toList();
  }
}
