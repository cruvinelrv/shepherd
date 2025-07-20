import 'package:test/test.dart';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
import 'package:shepherd/src/domain/services/analysis_service.dart';
import 'dart:io';

void main() {
  group('AnalysisService', () {
    late ShepherdDatabase db;
    late ConfigService configService;
    late AnalysisService analysisService;
    setUp(() async {
      final tempDir = Directory.systemTemp.createTempSync();
      db = ShepherdDatabase(tempDir.path);
      configService = ConfigService(db);
      analysisService = AnalysisService();
      await db.database;
    });
    tearDown(() async {
      await db.close();
    });

    test('analyzeProject returns results for domains', () async {
      final id = await db.insertPerson(
        firstName: 'Ana',
        lastName: 'Dev',
        email: 'ana.dev@example.com',
        type: 'lead_domain',
        githubUsername: 'anadev',
      );
      await configService.addDomain('domain3', [id]);
      final results = await analysisService.analyzeProject(db.projectPath);
      expect(results, isNotEmpty);
      expect(results.first.domainName, equals('domain3'));
    });
  });
}
