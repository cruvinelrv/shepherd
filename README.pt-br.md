# Shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

Motor avançado de automação e produtividade via CLI para Flutter/Dart. Simplifica os workflows de desenvolvimento (clean, deploy, changelog) e conecta o Design System aos testes com Atomic Design e Maestro.

## Instalação

Ou instale globalmente para usar a CLI (Recomendado):

```sh
dart pub global activate shepherd
```

Adicione ao seu `pubspec.yaml` para usar como pacote:

```yaml
dependencies:
  shepherd: ^0.9.0
```

## Contribuindo & Arquitetura

-   [**Guia de Contribuição**](CONTRIBUTING.md): Fluxo de trabalho, padrões de código e configuração.
-   [**Guia de Arquitetura**](doc/ARCHITECTURE.md): DDD, Clean Architecture e estrutura do projeto.

---

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

---

## Início Rápido

Começar com o Shepherd é fácil, seja iniciando um novo projeto ou ingressando em um existente.

### Início Rápido
```sh
# Simplesmente execute o Shepherd - ele irá guiá-lo pela configuração
shepherd
```

Quando você executa o Shepherd pela primeira vez em um projeto, ele detecta automaticamente que a configuração está faltando e apresenta opções:

1.  **Inicializar um novo projeto** - Configurar o Shepherd do zero
2.  **Importar de projeto existente** - Importar configuração de um repositório da equipe

### Modos de Configuração

Se você escolher inicializar, você selecionará um **modo de configuração**:

1.  **Apenas Automação**: Configuração leve para automação CI/CD.
    -   Configura: Informações do projeto, ambientes, detalhes do usuário
    -   Habilita: comandos `clean`, `changelog`, `deploy`
    -   Pula: Modelagem de domínio e gestão de equipe
    
2.  **Configuração Completa**: Gestão completa de projeto DDD.
    -   Tudo do modo Automação, mais:
    -   Registro de domínio e rastreamento de saúde
    -   Mapeamento de propriedade e responsabilidade da equipe
    -   Menu interativo para gestão contínua

**Resultado**: Gera arquivos de configuração (`.shepherd/project.yaml`, `.shepherd/environments.yaml`, etc.)

### Alternativa: Init Direto
```sh
# Você também pode executar init diretamente
shepherd init
```
**Recomendado para novos membros da equipe.** Este comando sincroniza seu banco de dados local com o arquivo `devops/domains.yaml` do projeto, importando todos os domínios e responsáveis para que você esteja pronto para trabalhar imediatamente.

---

## 1. Automação & CI/CD

### Limpeza de Projeto
```sh
# Limpar todos os projetos e microfrontends de uma vez
shepherd clean

# Limpar apenas o projeto atual
shepherd clean project
```
Útil para mono-repos onde você precisa executar `flutter clean` em vários pacotes.

> **Nota**: Este comando depende da configuração do projeto (gerada por `shepherd init`) para localizar todos os microfrontends registrados em `microfrontends.yaml`.

### Changelog Automático
```sh
shepherd changelog
```
Gerencia automaticamente seu `CHANGELOG.md` usando dois modos distintos baseados no seu branch atual:

1.  **Modo de Geração** (Branches de Feature):
    -   **Contexto**: Você está trabalhando em uma feature (ex: `feature/new-login`).
    -   **Ação**: Escaneia seus commits que estão à frente de `develop`.
    -   **Resultado**: Adiciona novas entradas ao `CHANGELOG.md` sob uma seção "Não Lançado".

2.  **Modo de Atualização** (Branches de Release/Main):
    -   **Contexto**: Você está em `release` ou `main`.
    -   **Ação**: Copia o changelog do branch de referência (ex: `develop`).
    -   **Resultado**: Atualiza o cabeçalho com a versão e data atuais.

> **Nota**: O versionamento é gerenciado pelo comando `shepherd deploy`, não pelo `changelog`.

### Geração de Testes Automatizados
```sh
shepherd test gen
```
Escaneia seu projeto em busca de anotações `@ShepherdTag` e `ShepherdPageKey` e gera automaticamente fluxos de teste para o **Maestro**.
- **Enriquecimento**: Utiliza dados do `.shepherd/shepherd_activity.yaml` para adicionar contexto aos fluxos.
- **Resultado**: Os flows são salvos em `.shepherd/maestro/flows/`.

### Geração de Tags
```sh
# Gera classes wrapper de tags a partir das anotações
shepherd tag gen
```
Escaneia seu código em busca de `@ShepherdPageKey` e `@ShepherdTag` para gerar classes wrapper tipadas. Garante que suas chaves de UI coincidam com o contrato de interação definido nas histórias de usuário.

### Gestão de Histórias e Atomic Design
```sh
# Gerenciar Histórias de Usuário
shepherd story add <id> <titulo> <dominio> <descrição>
shepherd story list

# Gerenciar Elementos de Design (Átomos, Moléculas, etc.)
shepherd element add <storyId> <elementId> <titulo> <tipo>
shepherd element list

# Gerenciar Tarefas Ágeis
shepherd task add <storyId> <titulo>
```
Organize seu ciclo de desenvolvimento com princípios de **Atomic Design**. Categorize elementos como `atom`, `molecule`, `organism` ou `token` para guiar a geração inteligente de testes.

### Pipeline de Deploy
```sh
shepherd deploy
```
Automatiza o fluxo completo de release:
-   Atualiza a versão em `pubspec.yaml`
-   Finaliza o `CHANGELOG.md`
-   Cria Pull Requests (com GitHub CLI ou Azure CLI)

> **Comportamento por Branch**:
> -   **develop**: Cria PR para `release`.
> -   **release**: Cria PR para `main`.
> -   **main**: Produção (sem PR).

### Pipeline de Release TBD (Trunk Based Development)
```sh
shepherd flow
```
Executa o fluxo automatizado de release localmente na branch principal (ex: `main`):

1.  **Validações Locais**: Garante que o desenvolvedor está na branch principal e sem alterações pendentes.
2.  **Incremento de Versão**: Solicita a escolha do tipo de incremento (patch, minor, major) ou mantém a versão atual.
3.  **Branch de Release**: Cria e alterna para a branch `release/vX.Y.Z` e atualiza o `pubspec.yaml` (root ou de todos os microfrontends).
4.  **Changelog**: Gera o `CHANGELOG.md` e arquiva o histórico antigo localmente.
5.  **Push & Pull Request**: Comita e faz push da branch de release para o remote origin, criando um Pull Request no GitHub com as notas de release usando o GitHub CLI (`gh`).
6.  **Limpeza**: Retorna para a branch principal local mantendo a área de trabalho limpa.

---

## 3. DDD & Gestão de Projetos 🚧 _Desenvolvimento Alpha_

O Shepherd ajuda você a manter uma arquitetura limpa gerenciando domínios, responsáveis e verificações de saúde.

### Análise de Saúde de Domínio
```sh
shepherd analyze
```
Verifica seu projeto em busca de violações arquiteturais, responsáveis ausentes ou problemas de estrutura.

### Gestão de Domínio
```sh
# Configurar domínios e responsáveis interativamente
shepherd config

# Adicionar um responsável a um domínio específico
shepherd add-owner <domínio>
```

### Persistência
```sh
shepherd export-yaml
```
Exporta todos os domínios e responsáveis registrados para `devops/domains.yaml`, permitindo que você versione as configurações de estrutura do seu projeto.

---

## Documentação

-   [**Guia de Contribuição**](CONTRIBUTING.md): Fluxo de trabalho, padrões de código e configuração.
-   [**Guia de Arquitetura**](doc/ARCHITECTURE.md): DDD, Clean Architecture e estrutura do projeto.

## Licença

MIT © 2026 Vinicius Cruvinel
