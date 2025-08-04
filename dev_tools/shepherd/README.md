# dev_tools/shepherd

This directory is intended for versionable configuration files and CI/CD artifacts related to your project.

YAML files generated and managed by Shepherd:

- `config.yaml`: Stores CLI and project configuration, including user and environment settings.
- `domains.yaml`: Stores the exported list of domains and owners for your DDD project. This file can be versioned and used in CI/CD pipelines or shared with the team.
- `environments.yaml`: Lists all registered environments and their associated branches.
- `feature_toggles.yaml`: Centralizes all feature toggles for the project, per domain, for versioning and CI/CD.
- `project.yaml`: Contains the project ID and name, used for identification and onboarding.
- `sync_config.yaml`: Defines which YAML files are required and their sync status for Shepherd CLI operations.

---

## Português (BR)

Este diretório é destinado a arquivos de configuração versionáveis e artefatos de CI/CD do seu projeto.

Arquivos YAML gerados e gerenciados pelo Shepherd:

- `config.yaml`: Armazena configurações do CLI e do projeto, incluindo usuários e ambientes.
- `domains.yaml`: Armazena a lista exportada de domínios e owners do seu projeto DDD. Este arquivo pode ser versionado e utilizado em pipelines de CI/CD ou compartilhado com o time.
- `environments.yaml`: Lista todos os ambientes registrados e seus branches associados.
- `feature_toggles.yaml`: Centraliza todos os feature toggles do projeto, por domínio, para versionamento e CI/CD.
- `project.yaml`: Contém o ID e nome do projeto, usado para identificação e onboarding.
- `sync_config.yaml`: Define quais arquivos YAML são obrigatórios e seu status de sincronização para operações do Shepherd CLI.

---

## Español

Este directorio está destinado a archivos de configuración versionables y artefactos de CI/CD relacionados con tu proyecto.

Archivos YAML generados y gestionados por Shepherd:

- `config.yaml`: Almacena la configuración del CLI y del proyecto, incluyendo usuarios y entornos.
- `domains.yaml`: Almacena la lista exportada de dominios y responsables de tu proyecto DDD. Este archivo puede ser versionado y utilizado en pipelines de CI/CD o compartido con el equipo.
- `environments.yaml`: Lista todos los entornos registrados y sus ramas asociadas.
- `feature_toggles.yaml`: Centraliza todos los feature toggles del proyecto, por dominio, para versionado e integración CI/CD.
- `project.yaml`: Contiene el ID y nombre del proyecto, usado para identificación y onboarding.
- `sync_config.yaml`: Define qué archivos YAML son obligatorios y su estado de sincronización para operaciones del Shepherd CLI.

