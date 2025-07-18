# shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

Uma ferramenta e package para gerenciar projetos DDD (Domain Driven Design) em Dart/Flutter, com análise de saúde de domínios, automação de limpeza, exportação YAML e integração CLI.

## Features

- CLI para análise de saúde dos domínios do projeto
- Comando de limpeza automática para múltiplos microfrontends (multi-pacotes)
- Exportação de resultados e histórico local
- Exportação de domínios e owners para YAML versionável
- Gerenciamento de owners (responsáveis) por domínio
- Pode ser usado como package para análise programática

## Instalação

Adicione ao seu `pubspec.yaml` para uso como package:

```yaml
dependencies:
  shepherd: ^0.0.1
```

Ou instale globalmente para usar a CLI:

```sh
dart pub global activate shepherd
```

## Uso via CLI

### Analisar domínios do projeto
```sh
shepherd analyze
```

### Limpar todos os projetos/microfrontends
```sh
shepherd clean
```

### Limpar apenas o projeto atual
```sh
shepherd clean project
```

### Configurar domínios e owners (interativo)
```sh
shepherd config
```

### Adicionar owner a um domínio existente
```sh
shepherd add-owner <dominio>
```

### Exportar domínios e owners para YAML versionável
```sh
shepherd export-yaml
# Gera o arquivo devops/domains.yaml
```

### Atualizar o changelog automaticamente
```sh
shepherd changelog
```

### Ajuda
```sh
shepherd help
```

## Uso como Package

```dart
import 'package:shepherd/shepherd.dart';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
import 'package:shepherd/src/domain/services/domain_info_service.dart';
import 'dart:io';

Future<void> main() async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final configService = ConfigService(shepherdDb);
  final infoService = DomainInfoService(shepherdDb);
  final analysisService = AnalysisService();

  // Cadastro de owners
  final aliceId = await shepherdDb.insertPerson(
    firstName: 'Alice', lastName: 'Silva', type: 'lead_domain');
  final bobId = await shepherdDb.insertPerson(
    firstName: 'Bob', lastName: 'Souza', type: 'developer');

  // Cadastro de domínios
  await configService.addDomain('auth_domain', [aliceId, bobId]);

  // Listar domínios
  final domains = await infoService.listDomains();
  print(domains);

  // Analisar domínios
  final results = await analysisService.analyzeProject(projectPath);
  print(results);

  await shepherdDb.close();
}
```

## Exemplo Completo

Veja exemplos completos e didáticos na pasta [`example/`](example/shepherd_example.dart).

## Exportação YAML

O comando `shepherd export-yaml` gera um arquivo `devops/domains.yaml` com todos os domínios e owners do projeto, pronto para versionamento e integração com CI/CD.

## Changelog Automático & Histórico

O comando `shepherd changelog` atualiza automaticamente o seu `CHANGELOG.md` com a versão e branch atual. Quando uma nova versão é detectada, as entradas anteriores do changelog são arquivadas em `dev_tools/changelog_history.md`, mantendo o changelog principal limpo e organizado.

- `CHANGELOG.md`: Sempre contém a versão mais recente e as mudanças atuais.
- `dev_tools/changelog_history.md`: Guarda todas as entradas antigas do changelog para referência histórica.

## License

MIT © 2025 Vinicius Cruvinel

## Suporte a Plataformas

**Atenção:** Este pacote é destinado ao uso em linha de comando e desktop/servidor. Não há suporte para Web devido ao uso de `dart:io`.
