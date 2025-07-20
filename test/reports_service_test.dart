import 'package:test/test.dart';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
import 'package:shepherd/src/domain/services/reports_service.dart';
import 'dart:io';

void main() {
  group('Reports Service', () {
    late ShepherdDatabase db;
    late ConfigService configService;
    late ReportsService infoService;
    setUp(() async {
      final tempDir = Directory.systemTemp.createTempSync();
      db = ShepherdDatabase(tempDir.path);
      configService = ConfigService(db);
      infoService = ReportsService(db);
      await db.database;
    });
    tearDown(() async {
      await db.close();
    });

    test('listDomains returns added domains', () async {
      final id = await db.insertPerson(
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
