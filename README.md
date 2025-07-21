# shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

A tool and package to manage DDD (Domain Driven Design) projects in Dart/Flutter, with domain health analysis, cleaning automation, YAML export, and CLI integration.

## Features

- CLI for domain health analysis
- Automatic cleaning command for multiple microfrontends (multi-packages)
- Export of results and local history
- Export of domains and owners to versionable YAML
- Owner (responsible) management per domain
- User story and task management, with support for linking stories to one or more domains (or globally)
- Robust interactive CLI with color, ASCII art, and persistent active user
- Prevents adding owners to non-existent domains
- Can be used as a package for programmatic analysis

## Installation

Add to your `pubspec.yaml` to use as a package:

```yaml
dependencies:
  shepherd: ^0.0.8
```

Or install globally to use the CLI:

```sh
dart pub global activate shepherd
```

## CLI Usage

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

### Initialize a new project (guided setup)
```sh
shepherd init
```
This command guides you through the initial setup of your project, allowing you to:
- Register domains (with validation and prevention of duplicates)
- Add owners (with email and GitHub username)
- Set repository type (GitHub or Azure)
- Configure initial project metadata
- Prepare all required files and database for Shepherd usage
- Cancel/return to main menu at any prompt by typing 9

## Package Usage

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
- **analysis_log**: Analysis execution logs
  - Columns: `id`, `timestamp`, `project_path`, `duration_ms`, `status`, `total_domains`, `unhealthy_domains`, `warnings`

> The database is created automatically on the first execution of any Shepherd command that requires persistence.

## User Stories & Tasks

Shepherd allows you to manage user stories and their tasks via the CLI, storing everything in the file `dev_tools/shepherd/shepherd_activity.yaml`.

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

## License

MIT © 2025 Vinicius Cruvinel

## Platform Support

**Note:** This package is intended for command-line and desktop/server use. Web platform is not supported due to reliance on `dart:io`.

---

### Recent CLI/UX improvements (0.0.6)

- All menus and prompts now support cancel/return with '9' at any step.
- Only existing domains can have owners or user stories linked.
- User stories can be linked to one or more domains, or globally.
- The 'Init' option was removed from the main menu (now only via `shepherd init`).
- The active user is now displayed and persisted.
- Improved error handling, validation, and user experience throughout the CLI.
