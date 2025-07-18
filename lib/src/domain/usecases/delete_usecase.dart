import 'package:shepherd/src/data/shepherd_database.dart';

class DeleteUseCase {
  final ShepherdDatabase db;
  DeleteUseCase(this.db);

  Future<void> deleteDomain(String domainName) async {
    await db.deleteDomain(domainName);
  }
}
