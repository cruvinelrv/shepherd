# Shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

Uma ferramenta e pacote para gerenciar projetos DDD (Domain Driven Design) em Dart/Flutter, com análise de saúde de domínios, automação de limpeza, exportação YAML e integração via CLI.

## Funcionalidades

## Arquitetura de Domínios Shepherd

O Shepherd é organizado em domínios principais, cada um responsável por uma parte do fluxo de gestão e automação:


```
+-------------------+
|     Shepherd      |
+-------------------+
         |
         +-----------------------------+
         |                             |
+--------+--------+         +----------+----------+
|     Domínios    |         |      Funções        |
+-----------------+         +---------------------+
|                 |         |                     |
|  config         |<------->|  Configuração,      |
|  deploy         |<------->|  Deploy,            |
|  init           |<------->|  Inicialização,     |
|  domains        |<------->|  Domínios de negócio|
|  menu           |<------->|  Menus & CLI UX     |
|  tools          |<------->|  Utilitários,       |
|  sync           |<------->|  Sincronização      |
+-----------------+         +---------------------+
```


**Detalhamento dos domínios:**

- **config**  - Gerencia configurações do projeto, ambientes, usuários.
- **deploy**  - Gerencia fluxo de deploy, PRs, versionamento.
- **init**    - Onboarding, criação e inicialização de projetos.
- **domains** - Lógica de negócio, entidades, casos de uso de domínio.
- **menu**    - Menus, navegação e experiência do usuário na CLI.
- **tools**   - Utilitários, helpers, serviços auxiliares.
- **sync**    - Sincronização de dados, import/export, integração com banco.

> Os domínios se comunicam principalmente via camada de domínio e serviços, mantendo o código modular e de fácil manutenção.


### DOMÍNIO
- Análise de saúde de domínios (CLI e programático)
- Gestão de responsáveis por domínio
- Gestão de histórias de usuário e tarefas, com suporte a vínculo de histórias a um ou mais domínios (ou global)
- Impede adicionar responsáveis ou histórias a domínios inexistentes
- Listar, vincular e analisar domínios e sua saúde
- Suporte nativo a projetos com múltiplos microfrontends (repositórios multi-package)
- Cada microfrontend pode ter seu próprio `pubspec.yaml` e versionamento, gerenciado via `microfrontends.yaml`
- Fluxos de deploy e versionamento detectam e atualizam apenas os microfrontends relevantes, com opção de também atualizar o `pubspec.yaml` raiz
- Comandos da CLI fornecem feedback claro sobre quais microfrontends foram atualizados
- Fluxos de onboarding e configuração orientam o cadastro e gestão de microfrontends
- Gestão centralizada de feature toggles por domínio, armazenados em `feature_toggles.yaml`
- Sincronização entre o YAML de feature toggles e o banco de dados local para consistência
- Comandos da CLI para regenerar, validar e exportar feature toggles de cada domínio
- Garante controle robusto e visibilidade de features habilitadas/desabilitadas em todos os domínios e microfrontends

### FERRAMENTAS
- CLI interativo robusto com cores, arte ASCII e usuário ativo persistente
- Pode ser usado como pacote para análise programática
- Comandos de ajuda e sobre
- Comando de limpeza automática para múltiplos microfrontends (multi-packages)

### DEPLOY
- Exportação de domínios e responsáveis para YAML versionável
- Exportação de resultados e histórico local
- Exportação YAML para integração CI/CD
- Comandos de changelog (gerenciamento automático de changelog e histórico)
- Abertura de Pull Request com integração GitHub CLI e Azure CLI (em breve)

### CONFIG
- Configuração interativa de domínios e responsáveis
- Importação/exportação de configuração do projeto via YAML
- Usuário ativo e configuração persistentes

## Instalação

Adicione ao seu `pubspec.yaml` para usar como pacote:

```yaml
dependencies:
  shepherd: ^0.5.1
```

Ou instale globalmente para usar a CLI:

```sh
dart pub global activate shepherd
```

## Uso (CLI - Recomendado)

A CLI é a principal e recomendada forma de usar o Shepherd. Ela oferece uma experiência robusta e interativa para gestão de projetos, análise e automação.

### Inicializar um novo projeto (setup guiado)
```sh
shepherd init
```
Este comando realiza a configuração inicial de um projeto gerenciado pelo Shepherd e normalmente é executado pela pessoa responsável pela configuração. Ele guia o registro de domínios, responsáveis, tipo de repositório e todos os metadados necessários. Use ao iniciar um novo projeto ou repositório.

> **Nota:** Se você está entrando em um projeto já existente (ex: após um `git pull`), o projeto já estará configurado e você terá todos os arquivos YAML necessários (como `devops/domains.yaml` e `shepherd_activity.yaml`). Nesse caso, **não** execute `shepherd init`. Em vez disso, apenas rode:

### Importar configuração do projeto
```sh
shepherd pull
```
Isso irá importar todos os domínios, responsáveis, histórias de usuário e tarefas dos arquivos YAML para o banco de dados local, e solicitará que você selecione ou registre seu usuário ativo. Este é o primeiro passo recomendado para qualquer desenvolvedor ingressando em um projeto Shepherd já configurado.

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

### Adicionar responsável a um domínio existente (apenas domínios existentes)
```sh
shepherd add-owner <domínio>
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
- Solicita o usuário ativo e valida no YAML
- Se o usuário não existir, permite adicionar um novo responsável interativamente e atualiza o YAML
- Importa todos os domínios, responsáveis, histórias de usuário e tarefas para o banco local para gestão robusta e versionada
- Garante que o usuário ativo seja sempre salvo em `user_active.yaml` em formato consistente

### Realizar deploy do projeto
```sh
shepherd deploy
```
Executa o fluxo completo de deploy: alteração de versão, geração automática do changelog, abertura de Pull Request e integração com ferramentas externas (GitHub CLI, Azure CLI).

## Exemplo Completo

Veja exemplos completos e didáticos na pasta [`example/`](example/shepherd_example.dart).

## Exportação YAML

O comando `shepherd export-yaml` gera o arquivo `devops/domains.yaml` com todos os domínios e responsáveis do projeto, pronto para versionamento e integração CI/CD.

## Changelog & Histórico Automático

O comando `shepherd changelog` atualiza automaticamente seu `CHANGELOG.md` com a versão e branch atuais. Quando uma nova versão é detectada, as entradas anteriores são arquivadas em `dev_tools/changelog_history.md`, mantendo seu changelog principal limpo e organizado.

- `CHANGELOG.md`: Sempre contém a versão mais recente e mudanças atuais.
- `dev_tools/changelog_history.md`: Armazena todas as entradas anteriores para referência histórica.

## Estrutura do Banco shepherd.db

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
- **stories**: Histórias de usuário
  - Colunas: `id`, `title`, `description`, `domains`, `status`, `created_by`, `created_at`
- **tasks**: Tarefas vinculadas às histórias
  - Colunas: `id`, `story_id`, `title`, `description`, `status`, `assignee`, `created_at`

> O banco é criado automaticamente na primeira execução de qualquer comando Shepherd que exija persistência.

## Histórias de Usuário & Tarefas

O Shepherd permite gerenciar histórias de usuário e tarefas via CLI, armazenando tudo no arquivo `.shepherd/shepherd_activity.yaml`.

- Adicione, liste e vincule histórias a um ou mais domínios (separados por vírgula) ou globalmente (deixe em branco)
- Cada história pode conter várias tarefas, com status, responsável e descrição
- O menu de histórias/tarefas pode ser acessado pelo menu de domínios
- Ao criar uma história, a CLI mostra todos os domínios disponíveis para seleção (ou deixe em branco para TODOS)
- Impede vínculo de histórias a domínios inexistentes

Exemplo de estrutura YAML gerada:

```yaml
- type: "user_story"
  id: "1234"
  title: "Pausar contribuições"
  description: "O objetivo é pausar contribuições via app e portal RH."
  domains: ["RH"]
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

> O arquivo é criado automaticamente ao adicionar a primeira história ou tarefa.

## Suporte a Plataformas

**Nota:** Este pacote é destinado ao uso em linha de comando e desktop/servidor. Plataforma web não é suportada devido ao uso de `dart:io`.

---

### Melhorias recentes na CLI/UX (0.0.6)

- Todos os menus e prompts agora suportam cancelar/voltar com '9' em qualquer etapa
- Apenas domínios existentes podem ter responsáveis ou histórias vinculadas
- Histórias podem ser vinculadas a um ou mais domínios, ou globalmente
- A opção 'Init' foi removida do menu principal (agora apenas via `shepherd init`)
- O usuário ativo agora é exibido e persistido
- Melhorias de validação, tratamento de erros e experiência do usuário em toda a CLI

---

## Uso como Pacote (Não Recomendado, mas Possível)

> **Nota:** O Shepherd é desenvolvido e mantido principalmente como uma ferramenta CLI para gestão, análise e automação de projetos. O uso direto como pacote Dart é possível, mas não recomendado e pode não ser suportado em versões futuras. Para melhores resultados e suporte total de recursos, utilize sempre a CLI do Shepherd.

Se ainda quiser experimentar a API do pacote, veja o exemplo abaixo (não oficialmente suportado):

```dart
// Exemplo apenas. O uso via CLI é fortemente recomendado.
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

## Licença

MIT © 2025 Vinicius Cruvinel
