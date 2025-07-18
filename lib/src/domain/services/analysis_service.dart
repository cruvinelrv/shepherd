import 'package:shepherd/src/domain/entities/domain_health_entity.dart';
import 'package:shepherd/src/utils/project_utils.dart';

/// Contract for DDD project analysis
abstract class IAnalysisService {
  Future<List<DomainHealthEntity>> analyzeProject(String projectPath);
}

/// Default implementation of the analysis service
class AnalysisService implements IAnalysisService {
  @override
  Future<List<DomainHealthEntity>> analyzeProject(String projectPath) async {
    print('Starting project analysis at: $projectPath');
    final startTime = DateTime.now();

    final results = <DomainHealthEntity>[];
    final allWarnings = <String>[];
    int totalDomains = 0;
    int unhealthyDomains = 0;

    // Instantiate the database with the project path
    final db = openShepherdDb();

    try {
      // Fetch registered domains
      final domains = await db.getAllDomainHealths();
      totalDomains = domains.length;
      if (domains.isEmpty) {
        print(
            'No domains registered. Please register domains before running the analysis.');
        return [];
      }

      for (final domain in domains) {
        final domainName = domain.domainName;
        print('Analyzing domain: $domainName...');
        // Here you can implement the actual domain metrics collection
        // Example: fetch git data, test coverage, etc.

        // For now, just add the domain to the results list
        final domainHealth = DomainHealthEntity(
          domainName: domainName,
          healthScore: 0.0,
          commitsSinceLastTag: 0,
          daysSinceLastTag: 0,
          warnings: const [],
        );
        results.add(domainHealth);
      }

      final endTime = DateTime.now();
      final durationMs = endTime.difference(startTime).inMilliseconds;

      // 5. Insert general analysis log into the local database
      await db.insertAnalysisLog(
        durationMs: durationMs,
        status: 'SUCCESS',
        totalDomains: totalDomains,
        unhealthyDomains: unhealthyDomains,
        warnings: allWarnings.join('; '),
      );

      print('Analysis completed in ${durationMs}ms.');
      return results;
    } catch (e) {
      final endTime = DateTime.now();
      final durationMs = endTime.difference(startTime).inMilliseconds;
      print('Error during analysis: $e');
      allWarnings.add('General error: $e');

      // Register error in the general log
      await db.insertAnalysisLog(
        durationMs: durationMs,
        status: 'FAILED',
        totalDomains: totalDomains,
        unhealthyDomains: unhealthyDomains,
        warnings: allWarnings.join('; '),
      );
      rethrow;
    } finally {
      // 6. Close the database
      await db.close();
    }
  }
}
