import 'package:shepherd/src/data/shepherd_database.dart';

class AddOwnerUseCase {
  final ShepherdDatabase db;
  AddOwnerUseCase(this.db);

  Future<List<Map<String, dynamic>>> getOwnersForDomain(
      String domainName) async {
    final dbInstance = await db.database;
    return dbInstance.rawQuery('''
      SELECT p.id, p.first_name, p.last_name, p.type FROM domain_owners o
      JOIN persons p ON o.person_id = p.id
      WHERE o.domain_name = ? AND o.project_path = ?
    ''', [domainName, db.projectPath]);
  }

  Future<List<Map<String, dynamic>>> getAllPersons() async {
    return await db.getAllPersons();
  }

  Future<int> addPerson(String firstName, String lastName, String type) async {
    return await db.insertPerson(
        firstName: firstName, lastName: lastName, type: type);
  }

  Future<void> addOwnerToDomain(String domainName, int personId) async {
    final dbInstance = await db.database;
    await dbInstance.insert('domain_owners', {
      'domain_name': domainName,
      'project_path': db.projectPath,
      'person_id': personId,
    });
  }
}
