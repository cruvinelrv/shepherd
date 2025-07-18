import 'package:shepherd/shepherd.dart';
import 'package:shepherd/src/data/shepherd_database.dart';

class ConfigUseCase {
  final ShepherdDatabase db;
  ConfigUseCase(this.db);

  Future<void> addDomain({
    required String domainName,
    double score = 0.0,
    int commits = 0,
    int days = 0,
    String warnings = '',
    List<int> personIds = const [],
  }) async {
    await db.insertDomain(
      domainName: domainName,
      score: score,
      commits: commits,
      days: days,
      warnings: warnings,
      personIds: personIds,
      projectPath: db.projectPath,
    );
  }

  Future<int> addOwnerToDomain(String domainName, Map<String, dynamic> owner) async {
    // Register the person and return the ID
    final ownerId = await db.insertPerson(
      firstName: owner['first_name'],
      lastName: owner['last_name'],
      type: owner['type'],
    );

    // Update the domain to include the new owner
    final domains = await db.getAllDomainHealths();
    final domain = domains.firstWhere(
      (d) => d.domainName == domainName,
      orElse: () => DomainHealthEntity(
        domainName: '',
        healthScore: 0.0,
        commitsSinceLastTag: 0,
        daysSinceLastTag: 0,
        warnings: [],
      ),
    );
    final currentOwners = await _getOwnerIdsForDomain(domainName);
    final updatedOwners = [...currentOwners, ownerId];
    await addDomain(
      domainName: domainName,
      score: domain.healthScore,
      commits: domain.commitsSinceLastTag,
      days: domain.daysSinceLastTag,
      warnings: (domain.warnings as List).join(';'),
      personIds: updatedOwners,
    );
    return ownerId;
  }

  Future<List<int>> _getOwnerIdsForDomain(String domainName) async {
    final dbInstance = await db.database;
    final rows = await dbInstance.rawQuery('''
      SELECT person_id FROM domain_owners
      WHERE domain_name = ? AND project_path = ?
    ''', [domainName, db.projectPath]);
    return rows.map((row) => row['person_id'] as int).toList();
  }

  Future<List<Map<String, dynamic>>> getDomains() async {
    final dbInstance = await db.database;
    return await dbInstance
        .query('domain_health', where: 'project_path = ?', whereArgs: [db.projectPath]);
  }

  Future<List<Map<String, dynamic>>> getOwners(String domainName) async {
    final dbInstance = await db.database;
    return await dbInstance.rawQuery('''
      SELECT p.* FROM domain_owners o
      JOIN persons p ON o.person_id = p.id
      WHERE o.domain_name = ? AND o.project_path = ?
    ''', [domainName, db.projectPath]);
  }

  Future<void> updateDomain(String domainName, Map<String, dynamic> updates) async {
    final dbInstance = await db.database;
    await dbInstance.update(
      'domain_health',
      updates,
      where: 'domain_name = ? AND project_path = ?',
      whereArgs: [domainName, db.projectPath],
    );
  }

  Future<void> removeOwnerFromDomain(String domainName, int ownerId) async {
    final dbInstance = await db.database;
    await dbInstance.delete(
      'domain_owners',
      where: 'domain_name = ? AND project_path = ? AND person_id = ?',
      whereArgs: [domainName, db.projectPath, ownerId],
    );
  }
}
