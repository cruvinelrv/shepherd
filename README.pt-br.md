# Shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

Uma ferramenta e pacote para gerenciar projetos DDD (Domain Driven Design) em Dart/Flutter, com análise de saúde de domínios, automação de limpeza, exportação YAML e integração CLI.

## Funcionalidades

- CLI para análise de saúde de domínios
- Comando de limpeza automática para múltiplos microfrontends (multi-packages)
- Exportação de resultados e histórico local
- Exportação de domínios e responsáveis para YAML versionável
- Gerenciamento de responsáveis (owners) por domínio
- Gestão de user stories e tarefas, com suporte a vínculo com um ou mais domínios (ou global)
- CLI interativa robusta com cor, arte ASCII e usuário ativo persistente
- Impede adicionar responsáveis a domínios inexistentes
- Pode ser usado como pacote para análise programática

## Instalação

Adicione ao seu `pubspec.yaml` para usar como pacote:

```yaml
dependencies:
  shepherd: ^0.1.0
```

Ou instale globalmente para usar a CLI:

```sh
dart pub global activate shepherd
```

## Uso da CLI

### Inicializar um novo projeto (setup guiado)
```sh
shepherd init
```
Este comando é responsável pela configuração inicial de um projeto gerenciado pelo Shepherd e normalmente é executado pela pessoa responsável pela configuração do projeto. Ele guia você pelo registro de domínios, responsáveis, tipo de repositório e todos os metadados necessários. Use ao iniciar um novo projeto ou repositório.

> **Nota:** Se você está entrando em um projeto já existente (por exemplo, após um `git pull`), o projeto já estará configurado e você terá todos os arquivos YAML necessários (como `devops/domains.yaml` e `shepherd_activity.yaml`). Nesse caso, **não** execute o `shepherd init`. Em vez disso, execute:

### Importar configuração do projeto
```sh
shepherd pull
```
Isso irá importar todos os domínios, responsáveis, user stories e tarefas dos arquivos YAML para seu banco de dados local, além de pedir para você selecionar ou registrar seu usuário ativo. Este é o primeiro passo recomendado para qualquer desenvolvedor que esteja entrando em um projeto Shepherd já configurado.

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

### Configurar domínios e responsáveis (interativo)
```sh
shepherd config
```

### Adicionar responsável a um domínio existente (apenas para domínios já existentes)
```sh
shepherd add-owner <dominio>
```

### Exportar domínios e responsáveis para YAML versionável
```sh
shepherd export-yaml
# Gera o arquivo devops/domains.yaml
```

### Atualizar changelog automaticamente
```sh
shepherd changelog
```

### Ajuda
```sh
shepherd help
```

### Sobre o Shepherd
```sh
shepherd about
```
Exibe informações do pacote, autor, homepage, repositório, documentação e licença em formato visualmente aprimorado. Links são clicáveis em terminais compatíveis.

### Fluxo híbrido: shepherd pull
```sh
shepherd pull
```
Sincroniza seu banco de dados local (`shepherd.db`) com o último `devops/domains.yaml` e log de atividades (`shepherd_activity.yaml`).
- Solicita o usuário ativo e valida no YAML.
- Se o usuário não existir, permite adicionar um novo responsável interativamente e atualiza o YAML.
- Importa todos os domínios, responsáveis, user stories e tarefas para o banco local para uma gestão robusta e versionada.
- Garante que o usuário ativo seja sempre salvo em `user_active.yaml` de forma consistente.

## Uso como Pacote

```dart
import 'package:shepherd/shepherd.dart';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
import 'dart:io';

Future<void> main() async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final configService = ConfigService(DomainsDatabase(projectPath));
  final infoService = DomainInfoService(shepherdDb);
  final analysisService = AnalysisService();

  // Registrar responsáveis
  final aliceId = await shepherdDb.insertPerson(
    firstName: 'Alice', lastName: 'Silva', type: 'lead_domain');
  final bobId = await shepherdDb.insertPerson(
    firstName: 'Bob', lastName: 'Souza', type: 'developer');

  // Registrar domínios
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

O comando `shepherd export-yaml` gera o arquivo `devops/domains.yaml` com todos os domínios e responsáveis do projeto, pronto para versionamento e integração CI/CD.

## Changelog & Histórico Automático

O comando `shepherd changelog` atualiza automaticamente seu `CHANGELOG.md` com a versão e branch atuais. Quando uma nova versão é detectada, as entradas anteriores são arquivadas em `dev_tools/changelog_history.md`, mantendo seu changelog principal limpo e organizado.

- `CHANGELOG.md`: Sempre contém a versão mais recente e mudanças atuais.
- `dev_tools/changelog_history.md`: Armazena todas as entradas anteriores para referência histórica.

## Estrutura do Banco de Dados shepherd.db

O Shepherd usa um banco SQLite local para armazenar informações do projeto. As principais tabelas são:

- **pending_prs**: Pull Requests pendentes
  - Colunas: `id`, `repository`, `source_branch`, `target_branch`, `title`, `description`, `work_items`, `reviewers`, `created_at`
- **domain_health**: Histórico de saúde dos domínios
  - Colunas: `id`, `domain_name`, `timestamp`, `health_score`, `commits_since_last_tag`, `days_since_last_tag`, `warnings`, `project_path`
- **persons**: Pessoas (membros, responsáveis, etc)
  - Colunas: `id`, `first_name`, `last_name`, `email`, `type`, `github_username`
- **domain_owners**: Relação entre domínios e pessoas (responsáveis)
  - Colunas: `id`, `domain_name`, `project_path`, `person_id`
- **domains**: Domínios registrados
  - Colunas: `name`
- **analysis_log**: Logs de execução de análise
  - Colunas: `id`, `timestamp`, `project_path`, `duration_ms`, `status`, `total_domains`, `unhealthy_domains`, `warnings`
- **stories**: User stories
  - Colunas: `id`, `title`, `description`, `domains`, `status`, `created_by`, `created_at`
- **tasks**: Tarefas vinculadas a user stories
  - Colunas: `id`, `story_id`, `title`, `description`, `status`, `assignee`, `created_at`

> O banco é criado automaticamente na primeira execução de qualquer comando Shepherd que exija persistência.

## User Stories & Tarefas

O Shepherd permite gerenciar user stories e suas tarefas via CLI, armazenando tudo no arquivo `dev_tools/shepherd/shepherd_activity.yaml`.

- Adicione, liste e vincule user stories a um ou mais domínios (separados por vírgula) ou globalmente (deixe em branco).
- Cada user story pode conter várias tarefas, com status, responsável e descrição.
- O menu de stories/tarefas pode ser acessado pelo menu de domínios.
- Ao criar uma user story, a CLI mostrará todos os domínios disponíveis e permitirá selecionar quais vincular (ou deixar em branco para TODOS).
- Impede vincular stories a domínios inexistentes.

Exemplo de estrutura YAML gerada:

```yaml
- type: "user_story"
  id: "1234"
  title: "Pausar contribuições"
  description: "O objetivo é pausar contribuições pelo app e portal RH."
  domains: ["RH"]
  status: "open"
  created_by: "joao"
  created_at: "2025-07-20T16:12:33.249557"
  tasks:
    - id: "2323"
      title: "Implementar botão de pausar"
      description: "Adicionar botão na tela principal."
      status: "open"
      assignee: "maria"
      created_at: "2025-07-20T16:21:53.617055"
```

> O arquivo é criado automaticamente ao adicionar a primeira user story ou tarefa.

## Suporte a Plataformas

**Nota:** Este pacote é destinado ao uso em linha de comando e desktop/servidor. Não há suporte para Web devido ao uso de `dart:io`.

---
