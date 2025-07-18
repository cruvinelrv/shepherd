import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/entities/domain_health_entity.dart';

/// Service for reporting and retrieving domain health information.
class ReportsService {
  final ShepherdDatabase db;

  /// Creates a new [ReportsService] with the given database.
  ReportsService(this.db);

  /// Returns a list of all domain health entities in the project.
  Future<List<DomainHealthEntity>> listDomains() async {
    return await db.getAllDomainHealths();
  }

  /// Returns the health information for a specific domain by name, or null if not found.
  Future<DomainHealthEntity?> getDomainInfo(String domainName) async {
    final all = await db.getAllDomainHealths();
    try {
      return all.firstWhere((d) => d.domainName == domainName);
    } catch (_) {
      return null;
    }
  }
}
