import 'package:shepherd/src/data/datasources/local/domains_database.dart';

/// Use case for listing domains and their owners.
class ListUseCase {
  final DomainsDatabase db;
  ListUseCase(this.db);

  /// Returns a list of all domains with their associated owners and warnings.
  Future<List<Map<String, dynamic>>> getDomainsWithOwners() async {
    final domains = await db.getAllDomainHealths();
    final database = await db.database;
    final List<Map<String, dynamic>> result = [];
    for (final domain in domains) {
      final ownerRows = await database.rawQuery('''
        SELECT p.first_name, p.last_name, p.type FROM domain_owners o
        JOIN persons p ON o.person_id = p.id
        WHERE o.domain_name = ? AND o.project_path = ?
      ''', [domain.domainName, db.projectPath]);
      result.add({
        'name': domain.domainName,
        'owners': ownerRows,
        'warnings': domain.warnings,
      });
    }
    return result;
  }
}
