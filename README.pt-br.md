# shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

Uma ferramenta e package para gerenciar projetos DDD (Domain Driven Design) em Dart/Flutter, com análise de saúde de domínios, automação de limpeza, exportação YAML e integração CLI.

## Features

- CLI para análise de saúde dos domínios do projeto
- Comando de limpeza automática para múltiplos microfrontends (multi-pacotes)
- Exportação de resultados e histórico local
- Exportação de domínios e owners para YAML versionável
- Gerenciamento de owners (responsáveis) por domínio
- Gerenciamento de user stories e tasks, com suporte a vinculação a um ou mais domínios (ou global)
- CLI interativa robusta com cores, ASCII art e usuário ativo persistente
- Impede adicionar owners a domínios inexistentes
- Pode ser usado como package para análise programática

## Instalação

Adicione ao seu `pubspec.yaml` para uso como package:

```yaml
dependencies:
  shepherd: ^0.0.6
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
*Apenas para domínios já cadastrados*

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

### Inicializar um novo projeto (setup guiado)
```sh
shepherd init
```
Este comando guia você pelo setup inicial do projeto, permitindo:
- Cadastrar domínios (com validação e prevenção de duplicidade)
- Adicionar owners (com email e usuário do GitHub)
- Definir o tipo de repositório (GitHub ou Azure)
- Configurar metadados iniciais do projeto
- Preparar todos os arquivos e banco necessários para uso do Shepherd
- Cancelar/voltar ao menu principal em qualquer prompt digitando 9

## Uso como Package

```dart
import 'package:shepherd/shepherd.dart';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
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

---

### Melhorias recentes de CLI/UX (0.0.6)

- Todos os menus e prompts agora suportam cancelar/voltar com '9' em qualquer etapa.
- Só é possível adicionar owners ou user stories a domínios existentes.
- User stories podem ser vinculadas a um ou mais domínios, ou globalmente.
- A opção 'Init' foi removida do menu principal (agora apenas via `shepherd init`).
- O usuário ativo agora é exibido e persiste.
- Melhorias de validação, tratamento de erros e experiência do usuário em toda a CLI.

## Estrutura do Banco de Dados shepherd.db

O Shepherd utiliza um banco SQLite local para armazenar informações do projeto. As principais tabelas são:

- **pending_prs**: Pull Requests pendentes
  - Colunas: `id`, `repository`, `source_branch`, `target_branch`, `title`, `description`, `work_items`, `reviewers`, `created_at`
- **domain_health**: Histórico de saúde dos domínios
  - Colunas: `id`, `domain_name`, `timestamp`, `health_score`, `commits_since_last_tag`, `days_since_last_tag`, `warnings`, `project_path`
- **persons**: Pessoas (membros, owners, etc)
  - Colunas: `id`, `first_name`, `last_name`, `email`, `type`, `github_username`
- **domain_owners**: Relação entre domínios e pessoas (owners)
  - Colunas: `id`, `domain_name`, `project_path`, `person_id`
- **analysis_log**: Logs de execuções de análise
  - Colunas: `id`, `timestamp`, `project_path`, `duration_ms`, `status`, `total_domains`, `unhealthy_domains`, `warnings`

> O banco é criado automaticamente na primeira execução de qualquer comando Shepherd que precise de persistência.

## User Stories e Tasks
O Shepherd permite gerenciar user stories e suas tasks pelo CLI, armazenando tudo no arquivo `dev_tools/shepherd/shepherd_activity.yaml`.

- Adicione, liste e relacione user stories a um ou mais domínios (separados por vírgula) ou globalmente (deixe em branco).
- Cada user story pode conter várias tasks, com status, responsável e descrição.
- O menu de histórias/tarefas pode ser acessado pelo menu de domínios.
- Ao criar uma user story, a CLI mostra todos os domínios disponíveis e permite selecionar em quais vincular (ou deixar em branco para TODOS).
- Impede vincular stories a domínios inexistentes.

Exemplo de estrutura YAML gerada:

```yaml
- type: "user_story"
  id: "1234"
  title: "Pausar contribuições"
  description: "O objetivo é pausar contribuições pelo app e portal RH."
  domains: [""RH"]
  status: "open"
  created_by: "joao"
  created_at: "2025-07-20T16:12:33.249557"
  tasks:
    - id: "2323"
      title: "Implementar botão de pausa"
      description: "Adicionar botão na tela principal."
      status: "open"
      assignee: "maria"
      created_at: "2025-07-20T16:21:53.617055"
```

> O arquivo é criado automaticamente ao adicionar a primeira user story ou task.
