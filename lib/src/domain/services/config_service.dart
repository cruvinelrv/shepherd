import 'package:shepherd/src/data/shepherd_database.dart';

class ConfigService {
  final ShepherdDatabase db;
  ConfigService(this.db);

  Future<void> addDomain(String domainName, List<int> personIds) async {
    // Verifica se já existe domínio com esse nome no projeto
    final existing = await db.database.then((dbInst) => dbInst.query(
          'domain_health',
          where: 'domain_name = ? AND project_path = ?',
          whereArgs: [domainName, db.projectPath],
        ));
    if (existing.isNotEmpty) {
      throw Exception('Já existe um domínio com o nome "$domainName" neste projeto.');
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

  Future<void> removeDomain(String domainName) async {
    await db.deleteDomain(domainName);
  }
}
