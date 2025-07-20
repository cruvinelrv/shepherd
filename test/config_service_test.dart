import 'package:shepherd/src/data/datasources/local/shepherd_database.dart';
import 'package:test/test.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
import 'dart:io';

void main() {
  group('ConfigService', () {
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

    test('addDomain prevents duplicates', () async {
      final id = await db.insertPerson(
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
