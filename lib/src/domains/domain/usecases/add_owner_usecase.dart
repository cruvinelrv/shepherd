import 'package:shepherd/src/domains/data/datasources/local/domains_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AddOwnerUseCase {
  /// Creates a domain with minimal default values.
  Future<void> createDomain(String domainName) async {
    await db.insertDomain(
      domainName: domainName,
      score: 100.0,
      commits: 0,
      days: 0,
      warnings: '',
      personIds: [],
      projectPath: db.projectPath,
    );
  }

  final DomainsDatabase db;
  AddOwnerUseCase(this.db);

  Future<List<Map<String, dynamic>>> getOwnersForDomain(String domainName) async {
    return await db.getOwnersForDomain(domainName);
  }

  Future<List<Map<String, dynamic>>> getAllPersons() async {
    final dbInstance = await db.database;
    return await dbInstance.query('persons');
  }

  Future<int> addPerson(String firstName, String lastName, String email, String type,
      [String? githubUsername]) async {
    final dbInstance = await db.database;
    return await dbInstance.insert('persons', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'type': type,
      'github_username': githubUsername,
    });
  }

  Future<void> addOwnerToDomain(String domainName, int personId) async {
    final dbInstance = await db.database;
    await dbInstance.insert(
        'domain_owners',
        {
          'domain_name': domainName,
          'project_path': db.projectPath,
          'person_id': personId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
