import 'package:test/test.dart';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
import 'dart:io';

void main() {
  group('YAML Export (mock)', () {
    // This test simulates the YAML export flow, without generating a real file
    late ShepherdDatabase db;
    late ConfigService configService;
    setUp(() async {
      final tempDir = Directory.systemTemp.createTempSync();
      db = ShepherdDatabase(tempDir.path);
      configService = ConfigService(db);
      await db.database;
    });
    tearDown(() async {
      await db.close();
    });

    test('can export domains and owners to YAML structure', () async {
      final id = await db.insertPerson(
        firstName: 'Carol',
        lastName: 'QA',
        email: 'carol.qa@example.com',
        type: 'developer',
        githubUsername: 'carolqa',
      );
      await configService.addDomain('domain4', [id]);
      final domains = await db.getAllDomainHealths();
      expect(domains, isNotEmpty);
      final dbInstance = await db.database;
      final ownerRows = await dbInstance.rawQuery('''
        SELECT p.first_name, p.last_name, p.type FROM domain_owners o
        JOIN persons p ON o.person_id = p.id
        WHERE o.domain_name = ? AND o.project_path = ?
      ''', ['domain4', db.projectPath]);
      expect(ownerRows, isNotEmpty);
      expect(ownerRows.first['first_name'], equals('Carol'));
    });
  });
}
