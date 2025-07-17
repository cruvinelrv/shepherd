import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/entities/domain_health_entity.dart';

class DomainInfoService {
  final ShepherdDatabase db;
  DomainInfoService(this.db);

  Future<List<DomainHealthEntity>> listDomains() async {
    return await db.getAllDomainHealths();
  }

  Future<DomainHealthEntity?> getDomainInfo(String domainName) async {
    final all = await db.getAllDomainHealths();
    try {
      return all.firstWhere((d) => d.domainName == domainName);
    } catch (_) {
      return null;
    }
  }
}
