import 'dart:io';

import 'package:shepherd/src/domains/domain/entities/domain_health_entity.dart';
import 'package:shepherd/src/domains/domain/services/analysis_service.dart';

class AnalyzeUseCase {
  final AnalysisService analysisService;
  AnalyzeUseCase(this.analysisService);

  Future<List<DomainHealthEntity>> analyzeDomains() async {
    return await analysisService.analyzeProject(Directory.current.path);
  }
}
