import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:shepherd/src/domains/domain/entities/enhanced_feature_toggle_entity.dart';

class EnhancedFeatureToggleDatabase {
  final String projectPath;
  Database? _database;

  EnhancedFeatureToggleDatabase(this.projectPath);

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

    // Create expanded table with all DynamoDB fields
    await db.execute('''
      CREATE TABLE IF NOT EXISTS enhanced_feature_toggles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        enabled INTEGER NOT NULL,
        domain TEXT NOT NULL,
        description TEXT,
        activity TEXT,
        prototype TEXT,
        team TEXT,
        ignore_docs TEXT,
        ignore_bundle_names TEXT,
        block_bundle_names TEXT,
        min_version TEXT,
        max_version TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    return db;
  }

  Future<int> insertFeatureToggle(EnhancedFeatureToggleEntity toggle) async {
    final db = await database;

    // Check name uniqueness
    final existing =
        await db.query('enhanced_feature_toggles', where: 'name = ?', whereArgs: [toggle.name]);

    if (existing.isNotEmpty) {
      throw Exception('Já existe um Feature Toggle com o nome "${toggle.name}".');
    }

    final now = DateTime.now();
    final toggleWithTimestamp = toggle.copyWith(
      createdAt: toggle.createdAt ?? now,
      updatedAt: now,
    );

    return await db.insert('enhanced_feature_toggles', toggleWithTimestamp.toMap());
  }

  Future<void> updateFeatureToggleById(int id, EnhancedFeatureToggleEntity updated) async {
    final db = await database;

    final updatedWithTimestamp = updated.copyWith(
      id: id,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'enhanced_feature_toggles',
      updatedWithTimestamp.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteFeatureToggleById(int id) async {
    final db = await database;
    await db.delete(
      'enhanced_feature_toggles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<EnhancedFeatureToggleEntity>> getAllFeatureToggles() async {
    final db = await database;
    final result = await db.query('enhanced_feature_toggles', orderBy: 'name');
    return result.map((row) => EnhancedFeatureToggleEntity.fromMap(row)).toList();
  }

  Future<List<EnhancedFeatureToggleEntity>> getFeatureTogglesByDomain(String domain) async {
    final db = await database;
    final result = await db.query('enhanced_feature_toggles',
        where: 'domain = ?', whereArgs: [domain], orderBy: 'name');
    return result.map((row) => EnhancedFeatureToggleEntity.fromMap(row)).toList();
  }

  Future<List<EnhancedFeatureToggleEntity>> getFeatureTogglesByTeam(String team) async {
    final db = await database;
    final result = await db.query('enhanced_feature_toggles',
        where: 'team = ?', whereArgs: [team], orderBy: 'name');
    return result.map((row) => EnhancedFeatureToggleEntity.fromMap(row)).toList();
  }

  Future<EnhancedFeatureToggleEntity?> getFeatureToggleByName(String name) async {
    final db = await database;
    final result =
        await db.query('enhanced_feature_toggles', where: 'name = ?', whereArgs: [name], limit: 1);

    if (result.isEmpty) return null;
    return EnhancedFeatureToggleEntity.fromMap(result.first);
  }

  Future<List<EnhancedFeatureToggleEntity>> getEnabledFeatureToggles() async {
    final db = await database;
    final result = await db.query('enhanced_feature_toggles',
        where: 'enabled = ?', whereArgs: [1], orderBy: 'name');
    return result.map((row) => EnhancedFeatureToggleEntity.fromMap(row)).toList();
  }

  Future<void> toggleFeatureStatus(int id) async {
    final db = await database;

    // Find current toggle
    final current =
        await db.query('enhanced_feature_toggles', where: 'id = ?', whereArgs: [id], limit: 1);

    if (current.isEmpty) {
      throw Exception('Feature toggle não encontrado com id: $id');
    }

    final currentToggle = EnhancedFeatureToggleEntity.fromMap(current.first);
    final updated = currentToggle.copyWith(
      enabled: !currentToggle.enabled,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'enhanced_feature_toggles',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Importa feature toggles do arquivo DynamoDB Terraform
  Future<void> importFromDynamoDBTerraform(List<Map<String, dynamic>> dynamoItems) async {
    final db = await database;

    await db.transaction((txn) async {
      for (final item in dynamoItems) {
        final name = item['name']?['S'] as String?;
        if (name == null) continue;

        final activity = item['activity']?['S'] as String?;
        final description = item['description']?['S'] as String?;
        final prototype = item['prototype']?['S'] as String?;
        final status = item['status']?['N'] as String?;
        final team = item['team']?['S'] as String?;
        final minVersion = item['minVersion']?['S'] as String?;
        final maxVersion = item['maxVersion']?['S'] as String?;

        // Process arrays
        final ignoreDocs = (item['ignoreDocs']?['SS'] as List?)
                ?.cast<String>()
                .where((s) => s.isNotEmpty)
                .toList() ??
            [];

        final ignoreBundleNames = (item['ignoreBundleNames']?['SS'] as List?)
                ?.cast<String>()
                .where((s) => s.isNotEmpty)
                .toList() ??
            [];

        final blockBundleNames = (item['blockBundleNames']?['SS'] as List?)
                ?.cast<String>()
                .where((s) => s.isNotEmpty)
                .toList() ??
            [];

        final toggle = EnhancedFeatureToggleEntity(
          name: name,
          enabled: status == '1',
          domain: _inferDomainFromName(name) ?? 'unknown',
          description: description ?? '',
          activity: activity?.isNotEmpty == true ? activity : null,
          prototype: prototype?.isNotEmpty == true ? prototype : null,
          team: team?.isNotEmpty == true ? team : null,
          ignoreDocs: ignoreDocs,
          ignoreBundleNames: ignoreBundleNames,
          blockBundleNames: blockBundleNames,
          minVersion: minVersion?.isNotEmpty == true ? minVersion : null,
          maxVersion: maxVersion?.isNotEmpty == true ? maxVersion : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Check if already exists
        final existing =
            await txn.query('enhanced_feature_toggles', where: 'name = ?', whereArgs: [name]);

        if (existing.isEmpty) {
          await txn.insert('enhanced_feature_toggles', toggle.toMap());
        } else {
          // Update existing
          final currentToggle = EnhancedFeatureToggleEntity.fromMap(existing.first);
          final updated = toggle.copyWith(
            id: currentToggle.id,
            createdAt: currentToggle.createdAt,
          );
          await txn.update('enhanced_feature_toggles', updated.toMap(),
              where: 'name = ?', whereArgs: [name]);
        }
      }
    });
  }

  /// Infers domain based on feature toggle name
  String? _inferDomainFromName(String name) {
    // Logic to infer domain based on naming patterns
    if (name.startsWith('home')) return 'home';
    if (name.startsWith('plan')) return 'plans';
    if (name.startsWith('corporate')) return 'corporate';
    if (name.startsWith('membership')) return 'membership';
    if (name.startsWith('portability')) return 'portability';
    if (name.startsWith('billing')) return 'billing';
    if (name.contains('Extra') || name.contains('extra')) {
      return 'contributions';
    }
    if (name.contains('Beneficiar') || name.contains('beneficiar')) {
      return 'beneficiaries';
    }
    if (name.contains('Fund') || name.contains('fund')) return 'funds';
    if (name.contains('Redemption') || name.contains('redemption')) {
      return 'redemptions';
    }

    return 'general';
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
