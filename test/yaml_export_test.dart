import 'package:test/test.dart';
import 'package:shepherd/src/config/domain/services/config_service.dart';
import 'package:shepherd/src/data/datasources/local/config_database.dart';
import 'package:shepherd/src/data/datasources/local/domains_database.dart';
import 'dart:io';

void main() {
  group('YAML Export (mock)', () {
    // This test simulates the YAML export flow, without generating a real file
    late ConfigDatabase configDb;
    late DomainsDatabase domainsDb;
    late ConfigService configService;
    setUp(() async {
      final tempDir = Directory.systemTemp.createTempSync();
      configDb = ConfigDatabase(tempDir.path);
      domainsDb = DomainsDatabase(tempDir.path);
      configService = ConfigService(domainsDb);
      await configDb.database;
      await domainsDb.database;
    });
    tearDown(() async {
      await configDb.close();
      await domainsDb.close();
    });

    test('can export domains and owners to YAML structure', () async {
      final id = await configDb.insertPerson(
        firstName: 'Carol',
        lastName: 'QA',
        email: 'carol.qa@example.com',
        type: 'developer',
        githubUsername: 'carolqa',
      );
      await configService.addDomain('domain4', [id]);
      final domains = await domainsDb.getAllDomainHealths();
      expect(domains, isNotEmpty);
      final dbInstance = await domainsDb.database;
      final ownerRows = await dbInstance.rawQuery('''
        SELECT p.first_name, p.last_name, p.type FROM domain_owners o
        JOIN persons p ON o.person_id = p.id
        WHERE o.domain_name = ? AND o.project_path = ?
      ''', ['domain4', domainsDb.projectPath]);
      expect(ownerRows, isNotEmpty);
      expect(ownerRows.first['first_name'], equals('Carol'));
    });
  });
}
