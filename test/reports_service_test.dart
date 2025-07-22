import 'package:shepherd/src/data/datasources/local/config_database.dart';
import 'package:test/test.dart';
import 'package:shepherd/src/config/domain/services/config_service.dart';
import 'package:shepherd/src/data/datasources/local/domains_database.dart';
import 'package:shepherd/src/domains/domain/services/reports_service.dart';
import 'dart:io';

void main() {
  group('Reports Service', () {
    late DomainsDatabase db;
    late ConfigDatabase configDb;
    late ConfigService configService;
    late ReportsService infoService;
    setUp(() async {
      final tempDir = Directory.systemTemp.createTempSync();
      db = DomainsDatabase(tempDir.path);
      configDb = ConfigDatabase(tempDir.path);
      configService = ConfigService(DomainsDatabase(tempDir.path));
      infoService = ReportsService(db);
      await db.database;
    });
    tearDown(() async {
      await configDb.close();
    });

    test('listDomains returns added domains', () async {
      final id = await configDb.insertPerson(
        firstName: 'A',
        lastName: 'B',
        email: 'a.b@example.com',
        type: 'developer',
        githubUsername: 'abdev',
      );
      await configService.addDomain('domain2', [id]);
      final domains = await infoService.listDomains();
      expect(domains, isNotEmpty);
      expect(domains.first.domainName, equals('domain2'));
    });
  });
}
