import 'package:shepherd/shepherd.dart';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
import 'package:shepherd/src/domain/services/domain_info_service.dart';
import 'dart:io';

/// Exemplo didático de uso do package shepherd
/// Demonstra como cadastrar domínios, associar owners, listar e analisar domínios.
Future<void> main() async {
  // Caminho do projeto (pasta atual)
  final projectPath = Directory.current.path;

  // Inicializa o banco e os serviços
  final shepherdDb = ShepherdDatabase(projectPath);
  final configService = ConfigService(shepherdDb);
  final infoService = DomainInfoService(shepherdDb);
  final analysisService = AnalysisService();

  print('--- Shepherd Example ---');

  // 1. Cadastro de owners (pessoas responsáveis)
  print('\nCadastrando owners de exemplo...');
  final aliceId = await shepherdDb.insertPerson(
    firstName: 'Alice',
    lastName: 'Silva',
    type: 'lead_domain',
  );
  final bobId = await shepherdDb.insertPerson(
    firstName: 'Bob',
    lastName: 'Souza',
    type: 'developer',
  );
  print('Owners cadastrados: Alice Silva (lead_domain), Bob Souza (developer)');

  // 2. Cadastro de domínios e associação de owners
  print('\nCadastrando domínios e associando owners...');
  final domains = ['auth_domain', 'user_domain', 'product_domain'];
  for (final domain in domains) {
    await configService.addDomain(domain, [aliceId, bobId]);
    print('Domínio "$domain" cadastrado com owners.');
  }

  // 3. Listagem dos domínios cadastrados
  print('\nDomínios cadastrados no projeto:');
  final domainList = await infoService.listDomains();
  for (final d in domainList) {
    print('- ${d.domainName}');
  }

  // 4. Análise dos domínios
  print('\nExecutando análise dos domínios...');
  final analysis = await analysisService.analyzeProject(projectPath);
  for (final result in analysis) {
    print(result);
  }

  // 5. Exportação (apenas informativo)
  print('\nPara exportar os domínios para YAML, utilize a CLI:');
  print('  dart run shepherd export-yaml');

  await shepherdDb.close();
  print('\n--- Fim do exemplo Shepherd ---');
}
