import 'package:shepherd/shepherd.dart';
import 'package:shepherd/src/config/domain/services/config_service.dart';
import 'package:shepherd/src/domains/data/datasources/local/domains_database.dart';
import 'package:shepherd/src/domains/domain/services/reports_service.dart';
import 'package:shepherd/src/config/data/datasources/local/config_database.dart';
import 'dart:io';

/// Example usage of the shepherd package
/// Demonstrates how to register domains, associate owners, list, and analyze domains.
Future<void> main() async {
  // Project path (current folder)
  final projectPath = Directory.current.path;

  // Initialize the database and services
  final domainsDb = DomainsDatabase(projectPath);
  final configDb = ConfigDatabase(projectPath);
  final configService = ConfigService(domainsDb);
  final infoService = ReportsService(domainsDb);
  final analysisService = AnalysisService();

  print('--- Shepherd Example ---');

  // 1. Register owners (responsible people)
  print('\nRegistering example owners...');
  final aliceId = await configDb.insertPerson(
    firstName: 'Alice',
    lastName: 'Silva',
    email: 'alice.silva@example.com',
    type: 'lead_domain',
    githubUsername: 'alicehub',
  );
  final bobId = await configDb.insertPerson(
    firstName: 'Bob',
    lastName: 'Souza',
    email: 'bob.souza@example.com',
    type: 'developer',
    githubUsername: 'bobdev',
  );
  print('Registered owners: Alice Silva (lead_domain), Bob Souza (developer)');

  // 2. Register domains and associate owners
  print('\nRegistering domains and associating owners...');
  final domains = ['auth_domain', 'user_domain', 'product_domain'];
  for (final domain in domains) {
    await configService.addDomain(domain, [aliceId, bobId]);
    print('Domain "$domain" registered with owners.');
  }

  // 3. List registered domains
  print('\nDomains registered in the project:');
  final domainList = await infoService.listDomains();
  for (final d in domainList) {
    print('- ${d.domainName}');
  }

  // 4. Analyze domains
  print('\nRunning domain analysis...');
  final analysis = await analysisService.analyzeProject(projectPath);
  for (final result in analysis) {
    print(result);
  }

  // 5. Export (informational only)
  print('\nTo export domains to YAML, use the CLI:');
  print('  shepherd export-yaml');

  await domainsDb.database.then((db) => db.close());
  await configDb.close();
  print('\n--- End of Shepherd example ---');
}
