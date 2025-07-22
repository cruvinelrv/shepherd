import 'package:shepherd/src/data/datasources/local/domains_database.dart';

class DeleteDomainUseCase {
  final DomainsDatabase db;
  DeleteDomainUseCase(this.db);

  Future<void> deleteDomain(String domainName) async {
    await db.deleteDomain(domainName);
  }
}
