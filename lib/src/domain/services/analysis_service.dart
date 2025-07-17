import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/entities/domain_health_entity.dart';

/// Contrato para análise de projetos DDD
abstract class IAnalysisService {
  Future<List<DomainHealthEntity>> analyzeProject(String projectPath);
}

/// Implementação padrão do serviço de análise
class AnalysisService implements IAnalysisService {
  @override
  Future<List<DomainHealthEntity>> analyzeProject(String projectPath) async {
    print('Iniciando análise do projeto em: $projectPath');
    final startTime = DateTime.now();

    final results = <DomainHealthEntity>[];
    final allWarnings = <String>[];
    int totalDomains = 0;
    int unhealthyDomains = 0;

    // Instancia o banco de dados com o caminho do projeto
    final db = ShepherdDatabase(projectPath);

    try {
      // Buscar domínios cadastrados
      final domains = await db.getAllDomainHealths();
      totalDomains = domains.length;
      if (domains.isEmpty) {
        print('Nenhum domínio cadastrado. Cadastre domínios antes de rodar a análise.');
        return [];
      }

      for (final domain in domains) {
        final domainName = domain.domainName;
        print('Analisando domínio: $domainName...');
        // Aqui você pode implementar a coleta real de métricas do domínio
        // Exemplo: buscar dados de git, cobertura de testes, etc.

        // Por enquanto, apenas adiciona o domínio à lista de resultados
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

      // 5. Inserir log geral da análise no banco de dados local
      await db.insertAnalysisLog(
        durationMs: durationMs,
        status: 'SUCCESS',
        totalDomains: totalDomains,
        unhealthyDomains: unhealthyDomains,
        warnings: allWarnings.join('; '),
      );

      print('Análise concluída em ${durationMs}ms.');
      return results;
    } catch (e) {
      final endTime = DateTime.now();
      final durationMs = endTime.difference(startTime).inMilliseconds;
      print('Erro durante a análise: $e');
      allWarnings.add('Erro geral: $e');

      // Registrar erro no log geral
      await db.insertAnalysisLog(
        durationMs: durationMs,
        status: 'FAILED',
        totalDomains: totalDomains,
        unhealthyDomains: unhealthyDomains,
        warnings: allWarnings.join('; '),
      );
      rethrow;
    } finally {
      // 6. Fechar o banco de dados
      await db.close();
    }
  }
  // Nenhuma simulação: implemente coleta real de métricas aqui futuramente.
}
