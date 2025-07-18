import 'package:shepherd/src/domain/services/analysis_service.dart';
import 'package:shepherd/src/domain/entities/domain_health_entity.dart';
import 'dart:io';

Future<void> runAnalyzeCommand() async {
  final analysisService = AnalysisService();
  final projectPath = Directory.current.path;

  print('Running "analyze" command...');

  try {
    final List<DomainHealthEntity> results = await analysisService.analyzeProject(projectPath);
    print('\n--- Analysis Results ---');
    if (results.isEmpty) {
      print('No domain found or analyzed.');
    } else {
      for (final domain in results) {
        print(domain);
      }
    }
    print('-----------------------------\n');
  } catch (e) {
    print('Analysis failed: $e');
    exit(1);
  }
}
