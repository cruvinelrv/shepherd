# shepherd

[Português (BR)](README.pt-br.md) | [English](README.md) | [Español](README.es.md)

A tool and package to manage DDD (Domain Driven Design) projects in Dart/Flutter, with domain health analysis, cleaning automation, YAML export, and CLI integration.

## Features

- CLI for domain health analysis
- Automatic cleaning command for multiple microfrontends (multi-packages)
- Export of results and local history
- Export of domains and owners to versionable YAML
- Owner (responsible) management per domain
- Can be used as a package for programmatic analysis

## Installation

Add to your `pubspec.yaml` to use as a package:

```yaml
dependencies:
  shepherd: ^0.0.1
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

### Add owner to an existing domain
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

## Package Usage

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

## License

MIT © 2025 Vinicius Cruvinel
