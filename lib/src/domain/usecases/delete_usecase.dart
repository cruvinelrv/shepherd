import 'package:shepherd/src/data/datasources/local/domains_database.dart';

class DeleteUseCase {
  final DomainsDatabase db;
  DeleteUseCase(this.db);

  Future<void> deleteDomain(String domainName) async {
    await db.deleteDomain(domainName);
  }
}
