# Shepherd Architecture Guide

Shepherd is built using **Domain-Driven Design (DDD)** principles and **Clean Architecture**. This document explains the project structure, layers, and key conventions.

## High-Level Overiew

The project is modularized by domains. Each major functionality of the CLI is encapsulated in its own domain directory under `lib/src/`.

```
lib/src/
├── config/       # Configuration management
├── deploy/       # Deployment automation
├── domains/      # Logic for managing user's domains
├── init/         # Project initialization flow
├── menu/         # CLI Menu and UX
├── sync/         # Data persistence and syncing
├── tools/        # Shared utilities and helpers
└── version.dart
```

## Layers of Architecture

Within each domain (e.g., `lib/src/deploy/`), we typically follow this structure:

### 1. Domain Layer (`domain/`)
The core business logic. **Must generally depend on nothing** (or only on other domains' entities/interfaces).

-   **Entities**: Represent the business objects.
    -   **Rule**: Must end with `Entity`.
    -   Example: `ProjectEntity`, `UserEntity`.
-   **Use Cases**: Encapsulate a specific business rule or action.
    -   Example: `DeployProjectUseCase`, `GetDomainHealthUseCase`.
-   **Repositories (Interfaces)**: Define how data is accessed, but not how it is implemented.
    -   Example: `IDeployRepository`.

### 2. Data Layer (`data/`)
The implementation of data access. Depends on the Domain Layer.

-   **Models**: Data transfer objects that extend Entities.
    -   **Rule**: Must end with `Model`.
    -   Example: `ProjectModel`, `UserModel`.
    -   Responsibility: `fromJson`, `toJson`, `fromDB`, etc.
-   **Datasources**: Low-level data access (API, DB, File System).
-   **Repositories (Implementation)**: Implements the interfaces defined in the Domain layer.
    -   Example: `DeployRepository`.

### 3. Presentation / Interface Layer
Since Shepherd is a CLI tool, our "Presentation" layer consists of:

-   **Commands**: Extend `args` Command class.
-   **Menus**: specific classes to handle user interaction (prompts, specialized prints).

## Dependency Rules

1.  **Domain Layer** should not depend on **Data Layer**.
2.  **Domain Layer** should not depend on specific external libraries/frameworks (when possible).
3.  **Data Layer** converts external data (JSON, SQL) into **Models**, and returns them as **Entities** to the Domain Layer.

## Specific Conventions

### Nomenclature
-   **Entities**: `<Name>Entity`
-   **Models**: `<Name>Model`
-   **Interfaces**: `I<Name>` (optional, but encouraged for Repositories)

### Dependency Injection
We manually inject dependencies via constructors to keep the cli lightweight and explicit.

## Directory Structure Example

```
lib/src/some_feature/
├── domain/
│   ├── entities/
│   │   └── some_thing_entity.dart
│   ├── repositories/
│   │   └── i_some_thing_repository.dart
│   └── usecases/
│       └── do_something_use_case.dart
└── data/
    ├── datasources/
    │   └── some_local_datasource.dart
    ├── models/
    │   └── some_thing_model.dart

## Shepherd Domain Architecture

Shepherd is organized into main domains, each responsible for a part of the management and automation flow:

```
+-------------------+
|     Shepherd      |
+-------------------+
         |
         +-----------------------------+
         |                             |
+--------+--------+         +----------+---------+
|     Domains     |         |      Functions     |
+-----------------+         +--------------------+
|                 |         |                    |
|  config         |<------->|  Configuration     |
|  deploy         |<------->|  Deploy            |
|  init           |<------->|  Initialization    |
|  domains        |<------->|  Business logic    |
|  menu           |<------->|  Menus & CLI UX    |
|  tools          |<------->|  Utilities         |
|  sync           |<------->|  Synchronization   |
+-----------------+         +--------------------+
```

**Domain details:**

- **config**  - Manages project settings, environments, users.
- **deploy**  - Handles deploy flow, PRs, versioning.
- **init**    - Onboarding, project creation and initialization.
- **domains** - Business logic, entities, domain use cases.
- **menu**    - CLI menus, navigation, and user experience.
- **tools**   - Utilities, helpers, auxiliary services.
- **sync**    - Data synchronization, import/export, database integration.

> Domains communicate mainly via the domain and service layers, keeping the code modular and maintainable.
