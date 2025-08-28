# Shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

A tool and package to manage DDD (Domain Driven Design) projects in Dart/Flutter, with domain health analysis, cleaning automation, YAML export, and CLI integration.

## Features

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

### DOMAIN
- Domain health analysis (CLI and programmatic)
- Owner (responsible) management per domain
- User story and task management, with support for linking stories to one or more domains (or globally)
- Prevents adding owners or stories to non-existent domains
- List, link, and analyze domains and their health
- Import/export project configuration from YAML
- Native support for projects with multiple microfrontends (multi-package repositories)
- Each microfrontend can have its own `pubspec.yaml` and versioning, managed via `microfrontends.yaml`
- Deploy and versioning flows detect and update only the relevant microfrontends, with the option to also update the root `pubspec.yaml`
- CLI commands provide clear feedback on which microfrontends are updated
- Onboarding and configuration flows guide you to register and manage microfrontends easily
- Centralized management of feature toggles per domain, stored in `feature_toggles.yaml`
- Synchronization between feature toggles YAML and the local database for consistency
- CLI commands to regenerate, validate, and export feature toggles for each domain
- Ensures robust control and visibility of enabled/disabled features across all domains and microfrontends

### TOOLS

## Installation

Add to your `pubspec.yaml` to use as a package:

```yaml
dependencies:
  shepherd: ^0.3.5
```

Or install globally to use the CLI:

```sh
dart pub global activate shepherd
```

## Usage (CLI - Recommended)

The CLI is the primary and recommended way to use Shepherd. It provides a robust, interactive experience for project management, analysis, and automation.

### Initialize a new project (guided setup)
```sh
shepherd init
```
This command is responsible for the initial setup of a Shepherd-managed project and is typically run by the person responsible for configuring the project. It guides you through registering domains, owners, repository type, and all required metadata. Use this when starting a new project or repository.

> **Note:** If you are joining an existing project (e.g., after a `git pull`), the project will already be configured and you will have all necessary YAML configuration files (such as `devops/domains.yaml` and `shepherd_activity.yaml`). In this case, you do **not** need to run `shepherd init`. Instead, simply run:

### Import project configuration
```sh
shepherd pull
```
This will import all domains, owners, user stories, and tasks from the YAML files into your local database, and prompt you to select or register your active user. This is the recommended first step for any developer joining an already-configured Shepherd project.

### Analyze project domains
```sh
shepherd analyze
```

### Clean all projects/microfrontends
```sh
shepherd clean
```

### Clean only the current project
```sh
shepherd clean project
```

### Configure domains and owners (interactive)
```sh
shepherd config
```

### Add owner to an existing domain (only for existing domains)
```sh
shepherd add-owner <domain>
```

### Export domains and owners to versionable YAML
```sh
shepherd export-yaml
# Generates the file devops/domains.yaml
```

### Update changelog automatically
```sh
shepherd changelog
```

### Help
```sh
shepherd help
```

### About Shepherd
```sh
shepherd about
```
Displays package information, author, homepage, repository, documentation, and license in a visually enhanced format. Links are clickable in supported terminals.

### Hybrid workflow: shepherd pull
```sh
shepherd pull
```
Synchronizes your local database (`shepherd.db`) with the latest `devops/domains.yaml` and activity log (`shepherd_activity.yaml`).
- Prompts for the active user and validates against the YAML file.
- If the user does not exist, allows you to add a new owner interactively and updates the YAML.
- Imports all domains, owners, user stories, and tasks into the local database for robust, versioned project management.
Ensures the active user is always saved in `user_active.yaml` in a consistent format.

### Deploy the project
```sh
shepherd deploy
```
Runs the full deploy workflow: version change, automatic changelog generation, Pull Request creation, and integration with external tools (GitHub CLI, Azure CLI).

## Full Example

See complete and didactic examples in the [`example/`](example/shepherd_example.dart) folder.

## YAML Export

The `shepherd export-yaml` command generates a `devops/domains.yaml` file with all project domains and owners, ready for versioning and CI/CD integration.

## Automatic Changelog & History

The command `shepherd changelog` automatically updates your `CHANGELOG.md` with the current version and branch. When a new version is detected, the previous changelog entries are archived in `dev_tools/changelog_history.md`, keeping your main changelog clean and organized.

- `CHANGELOG.md`: Always contains the latest version and recent changes.
- `dev_tools/changelog_history.md`: Stores all previous changelog entries for historical reference.



## shepherd.db Database Structure

Shepherd uses a local SQLite database to store project information. The main tables are:

- **pending_prs**: Pending Pull Requests
  - Columns: `id`, `repository`, `source_branch`, `target_branch`, `title`, `description`, `work_items`, `reviewers`, `created_at`
- **domain_health**: Domain health history
  - Columns: `id`, `domain_name`, `timestamp`, `health_score`, `commits_since_last_tag`, `days_since_last_tag`, `warnings`, `project_path`
- **persons**: People (members, owners, etc)
  - Columns: `id`, `first_name`, `last_name`, `email`, `type`, `github_username`
- **domain_owners**: Relation between domains and people (owners)
  - Columns: `id`, `domain_name`, `project_path`, `person_id`
- **domains**: Registered domains
  - Columns: `name`
- **analysis_log**: Analysis execution logs
  - Columns: `id`, `timestamp`, `project_path`, `duration_ms`, `status`, `total_domains`, `unhealthy_domains`, `warnings`
- **stories**: User stories
  - Columns: `id`, `title`, `description`, `domains`, `status`, `created_by`, `created_at`
- **tasks**: Tasks linked to user stories
  - Columns: `id`, `story_id`, `title`, `description`, `status`, `assignee`, `created_at`

> The database is created automatically on the first execution of any Shepherd command that requires persistence.

## User Stories & Tasks

Shepherd allows you to manage user stories and their tasks via the CLI, storing everything in the file `.shepherd/shepherd_activity.yaml`.

- Add, list, and link user stories to one or more domains (comma separated) or globally (leave blank).
- Each user story can contain several tasks, with status, assignee, and description.
- The stories/tasks menu can be accessed from the domains menu.
- When creating a user story, the CLI will show all available domains and let you select which ones to link (or leave blank for ALL).
- Prevents linking stories to non-existent domains.

Example of generated YAML structure:

```yaml
- type: "user_story"
  id: "1234"
  title: "Pause contributions"
  description: "The goal is to pause contributions via the app and HR portal."
  domains: ["HR"]
  status: "open"
  created_by: "joao"
  created_at: "2025-07-20T16:12:33.249557"
  tasks:
    - id: "2323"
      title: "Implement pause button"
      description: "Add button to main screen."
      status: "open"
      assignee: "maria"
      created_at: "2025-07-20T16:21:53.617055"
```

> The file is created automatically when you add the first user story or task.

## Platform Support

**Note:** This package is intended for command-line and desktop/server use. Web platform is not supported due to reliance on `dart:io`.

---

## Package Usage (Not Recommended, but Possible)

> **Note:** Shepherd is designed and maintained primarily as a CLI tool for project management, analysis, and automation. Direct usage as a Dart package is possible, but not recommended and may not be supported in future versions. For best results and full feature support, always use the Shepherd CLI.

If you still want to experiment with the package API, see the example below (not officially supported):

```dart
// Example only. CLI usage is strongly recommended.
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

  // Register owners
  final aliceId = await shepherdDb.insertPerson(
    firstName: 'Alice', lastName: 'Silva', type: 'lead_domain');
  final bobId = await shepherdDb.insertPerson(
    firstName: 'Bob', lastName: 'Souza', type: 'developer');

  // Register domains
  await configService.addDomain('auth_domain', [aliceId, bobId]);

  // List domains
  final domains = await infoService.listDomains();
  print(domains);

  // Analyze domains
  final results = await analysisService.analyzeProject(projectPath);
  print(results);

  await shepherdDb.close();
}
```

## License

MIT © 2025 Vinicius Cruvinel