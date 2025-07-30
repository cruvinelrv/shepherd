import 'package:shepherd/src/domains/data/datasources/local/domains_database.dart';

/// Fetches all owner emails for a given domain using the DomainsDatabase.
Future<List<String>> fetchOwnerEmailsForDomain(
    String domainName, String projectPath) async {
  final db = DomainsDatabase(projectPath);
  final owners = await db.getOwnersForDomain(domainName);
  // Assuming the person table has an 'email' field
  return owners.map((o) => o['email'] as String).toList();
}
