import 'package:shepherd/src/domain/services/analysis_service.dart';
import 'package:shepherd/src/domain/entities/domain_health_entity.dart';
import 'package:shepherd/src/data/datasources/local/domains_database.dart';
import 'dart:io';

Future<void> runAnalyzeCommand() async {
  final analysisService = AnalysisService();
  final projectPath = Directory.current.path;

  print('========================================');
  print('        Shepherd - Analyze Domains       ');
  print('========================================\n');

  try {
    final List<DomainHealthEntity> results = await analysisService.analyzeProject(projectPath);
    print('\n--- Analysis Results ---');
    if (results.isEmpty) {
      print('No domain found or analyzed.');
    } else {
      final db = DomainsDatabase(projectPath);
      for (final domain in results) {
        print('----------------------------------------');
        print('Domain:        ${domain.domainName}');
        print('Score:         ${domain.healthScore.toStringAsFixed(2)}');
        print('Commits:       ${domain.commitsSinceLastTag}');
        print('Days since tag:${domain.daysSinceLastTag}');
        if (domain.warnings.isNotEmpty) {
          print('Warnings:      ${domain.warnings.join(", ")}');
        }
        // Owners
        final owners = await db.getOwnersForDomain(domain.domainName);
        if (owners.isEmpty) {
          print('Owners:        (none)');
        } else {
          print('Owners:');
          for (final o in owners) {
            final gh = (o['github_username'] ?? '').toString();
            print('  - ${o['first_name']} ${o['last_name']} <${o['email']}> (${o['type']})'
                '${gh.isNotEmpty ? ' [GitHub: $gh]' : ''}');
          }
        }
      }
    }
    print('========================================\n');
  } catch (e) {
    print('Analysis failed: $e');
    exit(1);
  }
}
