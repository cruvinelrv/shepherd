import 'package:shepherd/src/data/datasources/local/domains_database.dart';

class AddOwnerUseCase {
  final DomainsDatabase db;
  AddOwnerUseCase(this.db);

  Future<List<Map<String, dynamic>>> getOwnersForDomain(String domainName) async {
    return await db.getOwnersForDomain(domainName);
  }

  Future<List<Map<String, dynamic>>> getAllPersons() async {
    // Implemente se necessário no DomainsDatabase
    throw UnimplementedError('getAllPersons não implementado em DomainsDatabase');
  }

  Future<int> addPerson(String firstName, String lastName, String email, String type,
      [String? githubUsername]) async {
    // Implemente se necessário no DomainsDatabase
    throw UnimplementedError('addPerson não implementado em DomainsDatabase');
  }

  Future<void> addOwnerToDomain(String domainName, int personId) async {
    // Implemente se necessário no DomainsDatabase
    throw UnimplementedError('addOwnerToDomain não implementado em DomainsDatabase');
  }
}
