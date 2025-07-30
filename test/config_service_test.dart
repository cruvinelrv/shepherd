import 'package:shepherd/src/config/data/datasources/local/config_database.dart';
import 'package:test/test.dart';
import 'package:shepherd/src/config/domain/services/config_service.dart';
import 'package:shepherd/src/domains/data/datasources/local/domains_database.dart';
import 'dart:io';

void main() {
  group('ConfigService', () {
    late DomainsDatabase db;
    late ConfigDatabase configDb;
    late ConfigService configService;
    setUp(() async {
      final tempDir = Directory.systemTemp.createTempSync();
      db = DomainsDatabase(tempDir.path);
      configDb = ConfigDatabase(tempDir.path);
      configService = ConfigService(DomainsDatabase(tempDir.path));
      await db.database;
    });
    tearDown(() async {
      await configDb.close();
    });

    test('addDomain prevents duplicates', () async {
      final id = await configDb.insertPerson(
        firstName: 'A',
        lastName: 'B',
        email: 'a.b@example.com',
        type: 'developer',
        githubUsername: 'abdev',
      );
      await configService.addDomain('domain1', [id]);
      expect(
        () async => await configService.addDomain('domain1', [id]),
        throwsA(isA<Exception>()),
      );
    });
  });
}
