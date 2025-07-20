import 'package:shepherd/src/domain/services/analysis_service.dart';
import 'package:shepherd/src/domain/entities/domain_health_entity.dart';
import 'package:shepherd/src/data/datasources/local/shepherd_database.dart';
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
      // Import ShepherdDatabase aqui para buscar owners
      final db = ShepherdDatabase(projectPath);
      for (final domain in results) {
        print(domain);
        // Buscar owners do domínio
        final owners = await db.getOwnersForDomain(domain.domainName);
        if (owners.isEmpty) {
          print('  Owners: (none)');
        } else {
          print('  Owners:');
          for (final o in owners) {
            final gh = (o['github_username'] ?? '').toString();
            print('    - ${o['first_name']} ${o['last_name']} <${o['email']}> (${o['type']})'
                '${gh.isNotEmpty ? ' [GitHub: $gh]' : ''}');
          }
        }
      }
    }
    print('-----------------------------\n');
  } catch (e) {
    print('Analysis failed: $e');
    exit(1);
  }
}
