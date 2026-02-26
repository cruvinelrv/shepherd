# Shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

Uma ferramenta e pacote para gerenciar projetos DDD (Domain Driven Design) em Dart/Flutter, com análise de saúde de domínios, automação de limpeza, exportação YAML e integração via CLI.

## Instalação

Ou instale globalmente para usar a CLI (Recomendado):

```sh
dart pub global activate shepherd
```

Adicione ao seu `pubspec.yaml` para usar como pacote:

```yaml
dependencies:
  shepherd: ^0.7.5
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
Escaneia seu projeto em busca de anotações `@ShepherdTag` e `ShepherdPageTag` e gera automaticamente fluxos de teste para o **Maestro**.
- **Enriquecimento**: Utiliza dados do `.shepherd/shepherd_activity.yaml` para adicionar contexto aos fluxos.
- **Resultado**: Os flows são salvos em `.shepherd/maestro/flows/`.

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
