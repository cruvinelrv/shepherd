import 'package:shepherd/shepherd.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
import 'package:shepherd/src/domain/services/reports_service.dart';
import 'package:shepherd/src/utils/project_utils.dart';
import 'dart:io';

/// Example usage of the shepherd package
/// Demonstrates how to register domains, associate owners, list, and analyze domains.
Future<void> main() async {
  // Project path (current folder)
  final projectPath = Directory.current.path;

  // Initialize the database and services
  final shepherdDb = openShepherdDb();
  final configService = ConfigService(shepherdDb);
  final infoService = ReportsService(shepherdDb);
  final analysisService = AnalysisService();

  print('--- Shepherd Example ---');

  // 1. Register owners (responsible people)
  print('\nRegistering example owners...');
  final aliceId = await shepherdDb.insertPerson(
    firstName: 'Alice',
    lastName: 'Silva',
    email: 'alice.silva@example.com',
    type: 'lead_domain',
    githubUsername: 'alicehub',
  );
  final bobId = await shepherdDb.insertPerson(
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

  await shepherdDb.close();
  print('\n--- End of Shepherd example ---');
}
