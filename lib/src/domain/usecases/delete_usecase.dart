import 'package:shepherd/src/data/datasources/local/shepherd_database.dart';

class DeleteUseCase {
  final ShepherdDatabase db;
  DeleteUseCase(this.db);

  Future<void> deleteDomain(String domainName) async {
    await db.deleteDomain(domainName);
  }
}
