import 'package:shepherd/src/data/datasources/local/config_database.dart';
import 'package:shepherd/src/data/datasources/local/domains_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ConfigUseCase {
  final ConfigDatabase configDb;
  final DomainsDatabase domainsDb;
  ConfigUseCase(this.configDb, this.domainsDb);

  Future<void> addDomain({
    required String domainName,
    double score = 0.0,
    int commits = 0,
    int days = 0,
    String warnings = '',
    List<int> personIds = const [],
  }) async {
    await domainsDb.insertDomain(
      domainName: domainName,
      score: score,
      commits: commits,
      days: days,
      warnings: warnings,
      personIds: personIds,
      projectPath: domainsDb.projectPath,
    );
  }

  /// Adds an owner to a domain, ensuring no duplicate owners are added.
  /// If the person does not exist, registers them and links to the domain.
  /// Returns the owner ID.
  Future<int> addOwnerToDomain(String domainName, Map<String, dynamic> owner) async {
    // Register or get the person and return the ID
    final ownerId = await configDb.insertPerson(
      firstName: owner['first_name'],
      lastName: owner['last_name'],
      email: owner['email'],
      type: owner['type'],
    );

    // Check if the owner is already linked to the domain
    final currentOwners = await _getOwnerIdsForDomain(domainName);
    if (currentOwners.contains(ownerId)) {
      // Owner already linked, do nothing
      return ownerId;
    }

    // Link the owner to the domain
    final dbInstance = await domainsDb.database;
    await dbInstance.insert(
      'domain_owners',
      {
        'domain_name': domainName,
        'person_id': ownerId,
        'project_path': domainsDb.projectPath,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return ownerId;
  }

  Future<List<int>> _getOwnerIdsForDomain(String domainName) async {
    final dbInstance = await domainsDb.database;
    final rows = await dbInstance.rawQuery('''
      SELECT person_id FROM domain_owners
      WHERE domain_name = ? AND project_path = ?
    ''', [domainName, domainsDb.projectPath]);
    return rows.map((row) => row['person_id'] as int).toList();
  }

  Future<List<Map<String, dynamic>>> getDomains() async {
    final dbInstance = await domainsDb.database;
    return await dbInstance
        .query('domain_health', where: 'project_path = ?', whereArgs: [domainsDb.projectPath]);
  }

  Future<List<Map<String, dynamic>>> getOwners(String domainName) async {
    final dbInstance = await domainsDb.database;
    return await dbInstance.rawQuery('''
      SELECT p.* FROM domain_owners o
      JOIN persons p ON o.person_id = p.id
      WHERE o.domain_name = ? AND o.project_path = ?
    ''', [domainName, domainsDb.projectPath]);
  }

  Future<void> updateDomain(String domainName, Map<String, dynamic> updates) async {
    final dbInstance = await domainsDb.database;
    await dbInstance.update(
      'domain_health',
      updates,
      where: 'domain_name = ? AND project_path = ?',
      whereArgs: [domainName, domainsDb.projectPath],
    );
  }

  Future<void> removeOwnerFromDomain(String domainName, int ownerId) async {
    final dbInstance = await domainsDb.database;
    await dbInstance.delete(
      'domain_owners',
      where: 'domain_name = ? AND project_path = ? AND person_id = ?',
      whereArgs: [domainName, domainsDb.projectPath, ownerId],
    );
  }
}
