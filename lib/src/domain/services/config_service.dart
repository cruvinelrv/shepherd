import 'package:shepherd/src/data/datasources/local/shepherd_database.dart';

/// Service for configuring domains and managing owners.
class ConfigService {
  final ShepherdDatabase db;
  ConfigService(this.db);

  /// Adds a new domain to the project with the given owners.
  /// Throws an exception if a domain with the same name already exists.
  Future<void> addDomain(String domainName, List<int> personIds) async {
    // Check if a domain with this name already exists in the project
    final existing = await db.database.then((dbInst) => dbInst.query(
          'domain_health',
          where: 'domain_name = ? AND project_path = ?',
          whereArgs: [domainName, db.projectPath],
        ));
    if (existing.isNotEmpty) {
      throw Exception(
          'A domain with the name "$domainName" already exists in this project.');
    }
    await db.insertDomain(
      projectPath: db.projectPath,
      domainName: domainName,
      score: 0.0,
      commits: 0,
      days: 0,
      warnings: '',
      personIds: personIds,
    );
  }

  /// Removes a domain from the project by its name.
  Future<void> removeDomain(String domainName) async {
    await db.deleteDomain(domainName);
  }
}
