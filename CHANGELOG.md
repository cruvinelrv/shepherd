
# CHANGELOG [0.0.6]

## 0.0.6 - 2025-07-20
- Data layer refactor:
  - Moved `ShepherdDatabase` to `lib/src/data/datasources/local/shepherd_database.dart` to follow Clean Architecture conventions for local datasources.
  - Updated all imports across the project to use the new path for `ShepherdDatabase`.
- CLI and menu improvements:
  - Modularized the project initialization flow (`shepherd init`) into smaller files: domain prompt, owner prompt, repo type prompt, GitHub username prompt, and summary.
  - Improved code organization in the presentation layer for easier maintenance and testing.
- Bug fixes and polish:
  - Fixed type safety in repo type prompt to ensure non-nullable return.
  - Removed unused imports and improved error handling in prompts.
  - All comments and user-facing strings are now in English for pub.dev compliance.
- Documentation:
  - Updated code comments and documentation for clarity and maintainability.
  - Added guidance on folder structure for datasources (local/remote) in Clean Architecture.

# CHANGELOG [0.0.5]

## 0.0.5 - 2025-07-18
- Refactored command structure:
  - All CLI commands are now centralized in `lib/src/presentation/commands/commands.dart` for easier import and maintenance.
  - Removed the `cli_helpers.dart` file, making the structure cleaner.
  - Updated command imports in `bin/shepherd.dart` to use only `commands.dart`.
- Export file updates:
  - The `lib/shepherd.dart` file now exports only `commands.dart` to centralize command access, while keeping entity and service exports.
- README updates:
  - Package usage example updated in English, Portuguese, and Spanish READMEs to reflect the new command export centralization.
  - Imports in examples are now simplified and aligned with the new structure.
- Improved code organization and modularization, following Clean Architecture and best practices for pub.dev publication.

# CHANGELOG [0.0.4]

## 0.0.4 - 2025-07-18
- Added platform support section to README in English, Portuguese, and Spanish, clarifying that the package is intended for CLI/desktop/server use and does not support Web or WASM (due to dart:io).
- Updated dependencies in pubspec.yaml.

## 0.0.3 - 2025-07-18
- Dart format applied

## 0.0.2 - 2025-07-18
- Provide home page and documentation

## 0.0.1 - 2025-07-18

- Initial release: CLI and package for DDD project management in Dart/Flutter
- Uses a local SQLite database (via sqflite_ffi) for persistent storage of domains, owners, and related data. No external server required.
- Domain health analysis, owner management, YAML export, and cleaning automation
- Interactive CLI and programmatic API
- Owner type field is now standardized across all flows (domain config and add-owner) using a single allowed list: administrator, developer, lead_domain. Prevents inconsistent or duplicate owner types.
