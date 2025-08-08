## 0.2.8 - 2025-08-08
- The root CHANGELOG.md now always prioritizes the version from the root pubspec.yaml. If it does not exist, it uses the version from the first microfrontend listed in microfrontends.yaml.
- Improved consistency between deploy and changelog flows for multi-microfrontend projects.
- Code cleanup and improved logic for version and changelog management.
## 0.2.8 - 2025-08-08
- The root CHANGELOG.md is now always updated using the version from the specified microfrontend's pubspec.yaml, even if there is no pubspec.yaml in the root directory.
- Improved deploy and changelog flows for multi-microfrontend projects: version and changelog logic now work seamlessly for any microfrontend.
- Updated documentation and version references for 0.2.8.
- Minor bug fixes and code cleanup for reliability.
## 0.2.7 - 2025-08-08
- Fix changelog logic: now only the root or first microfrontend's changelog is updated, with clearer archiving of previous entries.
- Updated documentation and README files to reflect the new version and features.
- Minor bug fixes and code cleanup for a more robust and professional CLI experience.
## 0.2.6 - 2025-08-08
- Improved multi-microfrontend versioning: Shepherd now updates the version in all microfrontends' `pubspec.yaml` files.
- Enhanced changelog management: The changelog is now updated for all microfrontends, not just the first one.
- Environment branch logic: Changelog updates are now correctly blocked only for branches listed in `environments.yaml`.
- Accurate CLI feedback: The CLI now displays clear and correct messages about changelog updates.
- Removed debug print statements from changelog logic.
- Documentation updates and minor bug fixes.

## 0.2.5 - 2025-08-06
  - shepherd pull now works even if user_active.yaml does not exist, as long as the project is already configured.
  - Fixed user/owner selection and creation flow to avoid duplication and scoping errors.
  - Code reorganized to ensure robustness and clarity in initialization and onboarding.
  - Minor consistency improvements and error messages.
## 0.2.4 - 2025-08-05
  - Now domains.yaml is updated automatically whenever an owner is added to a domain (no need to manually export anymore).
  - Improves workflow and consistency for domain/owner management.
  - Minor code improvements and error handling for YAML export.

## 0.2.3 - 2025-08-05
  - Fixed: changelog update now works even if there is no pubspec.yaml in the root directory; Shepherd will use the first microfrontend's pubspec.yaml automatically.
  - Prevents PathNotFoundException and improves deploy/versioning flow for microfrontend-based projects.
  - Minor code improvements and error handling for changelog logic.

## 0.2.2 - 2025-08-05
  - Restored the prompt asking whether to update the root pubspec.yaml when it exists, for safer and more flexible versioning flows.
  - If the root pubspec.yaml does not exist, Shepherd updates the first microfrontend's pubspec.yaml automatically.
  - Improved UX: clearer feedback when updating versions, and more control for the user in multi-project setups.
  - Minor code and documentation improvements.

## 0.2.1 - 2025-08-05
  - All user-facing messages, prompts, and comments standardized to English across the CLI and codebase.
  - Microfrontends prompt in shepherd init now only accepts yes/no answers in English, with validation and reprompting.
  - Improved help/about commands: now always available, even without project initialization.
  - Translated and improved all CLI feedback, error messages, and onboarding flows for internationalization and clarity.
  - Bug fixes and code cleanup for a more consistent and professional user experience.
## 0.2.0 - 2025-08-05
  - Context-aware versioning: deploy and menu flows now prompt to update only the correct pubspec.yaml files, with an option to also update the root pubspec.yaml when microfrontends exist.
  - Pull Request (PR) enable/disable: shepherd init now prompts for PR support and saves the setting in config.yaml, controlling PR options in deploy flows.
  - Improved feedback: clear messages indicate which microfrontends and pubspec.yaml files are updated during deploy/versioning.
  - Consistent UX: both interactive menu and automatic deploy flows now offer the same control over versioning and PR logic.
  - Documentation and example updates: README files and shepherd_example.dart updated to reflect new best practices and features.
  - Bug fixes and code cleanup for a more robust CLI experience.
## 0.1.9 - 2025-08-04
  - shepherd clean and shepherd project are now fully independent from shepherd.db and YAML files. Both commands are routed before any initialization or onboarding logic, ensuring they work in any directory, even without project initialization.
  - Fixed command routing and parser registration for shepherd project, making it a true alias for cleaning only the current project.
  - Minor code cleanup and improved command documentation.
## 0.1.8 - 2025-08-04
  - sync_config.yaml generation now always includes dev_tools/shepherd/domains.yaml as a required file, ensuring robust onboarding and sync flows.
  - Fixed type conversion bug when listing tasks from YAML, preventing runtime errors.
  - Updated all YAML export/import logic (domains.yaml, feature_toggles.yaml, etc.) to reflect the new dev_tools/shepherd/ structure.
  - Documentation (README and translations) updated to reflect new paths, onboarding, and sync flows.
  - Minor bug fixes, UX improvements, and code cleanup.
## 0.1.7 - 2025-08-04
  - domains.yaml migration: now exported and read from dev_tools/shepherd/domains.yaml instead of devops/domains.yaml.
  - Feature Toggles for domains: improved support and synchronization between feature_toggles.yaml and the database, with robust consistency checks and regeneration logic.
  - Updated all CLI commands (export, pull, init) to use the new path for domains.yaml.
  - Improved onboarding and sync flows to reflect the new YAML location and feature toggle management.
  - Documentation and help messages updated to reference the new paths and features.
  - Code cleanup and minor bug fixes related to the migration and YAML sync.
## 0.1.6 - 2025-07-30
- Major refactor: modularized all CLI commands and domain logic for maintainability.
- All configuration and domain logic migrated to YAML and new domain folders.
- Updated all documentation (README, translations) to reflect new structure and features.
- Fixed all import and build errors after folder restructuring.
- Improved onboarding, error handling, and CLI UX.
- Added .pubignore and changelog compliance for pub.dev publication.
- Bug fixes and code cleanup for a stable release.

## 0.1.5 - 2025-07-24
  - shepherd deploy: improved changelog step to avoid duplicate entries by checking the full branch description, not just the branch number.

## 0.1.4 - 2025-07-23
  - Environment management improved: now each environment is linked to a single branch.
  - Added environments management to the Config menu for easier access and editing.
  - shepherd init now prompts for both environment name and its branch, saving in the correct format.
  - All onboarding, deploy, and changelog flows updated to use the new environment-branch structure.
  - Bug fixes and code cleanup for a more robust and user-friendly CLI.

## 0.1.3 - 2025-07-23
  - Environment management: environments are now empty by default and must be configured interactively during shepherd init. No default environments are added automatically.
  - Improved deploy and changelog flows: changelog updates are blocked on environment branches, and the message is only shown once.
  - Deploy menu: removed unnecessary 'Version not changed.' message when exiting the menu.
  - CLI onboarding and error handling further improved for clarity and user experience.
  - Code cleanup and bug fixes for robust, professional CLI workflows.

## 0.1.2 - 2025-07-22
  - shepherd pull: onboarding flow improved. Now creates the devops directory interactively if missing, and if domains.yaml is missing, prompts to run shepherd init and launches it automatically if user agrees.
  - All onboarding and error flows are now more robust and user-friendly, with clear English-only messages.
  - Modularization and code cleanup: CLI protections and onboarding logic separated for maintainability.
  - README and translations updated to reflect new version and onboarding flow.
  - Minor bug fixes and improvements.

## 0.1.1 - 2025-07-22
  - Features in the README are now grouped by DOMAIN, TOOLS, DEPLOY, and CONFIG for better clarity.
  - Added a note in the DEPLOY section about Pull Request creation with GitHub CLI and Azure CLI integration (coming soon).
  - Minor documentation improvements and consistency fixes.
  
## 0.1.0 - 2025-07-21
  - Fixed and unified the format for `user_active.yaml` across all flows (init, pull, etc): now always writes the full user object (id, first_name, last_name, email, type, github_username) for consistent CLI experience.
  - Shepherd pull now uses the same user writing logic as shepherd init, preventing display bugs and ensuring correct active user info.
  - Refactored and cleaned up code in `pull_command.dart`, `edit_person_controller.dart`, `config_menu.dart`, and `shepherd_database.dart` for maintainability and internationalization.
  - Minor bug fixes and code cleanup.

## 0.0.9 - 2025-07-20
  - About command: now displays author, homepage, repository, and docs as clickable links (OSC 8 hyperlinks) and uses centralized ANSI color constants for a visually improved output.
  - All CLI colors and styles are now managed via `AnsiColors` for consistency.
  - Version updated to 0.0.9 in all READMEs.
  - Improved about command layout and border for a more professional look.
  - Removed deprecated `author`/`authors` fields from pubspec.yaml, author is now hardcoded in about.
  - README, README.pt-br.md, and README.es.md updated to reference version 0.0.9.
  - Minor bug fixes and code cleanup.
  
## 0.0.8 - 2025-07-20
  - Visual improvements to the Analyze domains command: clearer layout, domain information shown first, better separation and readability.
  - Fixed a bug in Shepherd init where the domain was not created before owner registration, causing "Domain does not exist" errors when adding owners during initialization. Now the domain is created immediately after entering its name.

## 0.0.7 - 2025-07-20
  - `dart format` on the entire project.
  - change the changelog display format

## 0.0.6 - 2025-07-20
- Data layer refactor:
  - Moved `ShepherdDatabase` to `lib/src/data/datasources/local/shepherd_database.dart` to follow Clean Architecture conventions for local datasources.
  - Updated all imports across the project to use the new path for `ShepherdDatabase`.
- CLI and menu improvements:
  - Modularized the project initialization flow (`shepherd init`) into smaller files: domain prompt, owner prompt, repo type prompt, GitHub username prompt, and summary.
  - Improved code organization in the presentation layer for easier maintenance and testing.
  - Main menu and all submenus now follow Dart CLI standards, with improved color and ASCII art.
  - The 'Init' option was removed from the main menu (now only available via `shepherd init`).
  - All submenus now support both '0. Exit' and '9. Back to main menu'.
  - The active user is now displayed and persisted.
  - Domains menu: now lists available domains for user story/task management, and prevents adding owners to non-existent domains.
  - User stories/tasks: when creating a user story, the user can select one or more domains (comma separated) or leave blank for ALL; prompt is only shown at the right moment.
  - Removed redundant prompts for domain selection in user story flow.
- Bug fixes and polish:
  - Fixed type safety in repo type prompt to ensure non-nullable return.
  - Removed unused imports and improved error handling in prompts.
  - All comments and user-facing strings are now in English for pub.dev compliance.
  - Prevented adding owners to non-existent domains.
  - Improved validation and user experience in all prompts (cancel/return, empty input, etc).
- Documentation:
  - Updated code comments and documentation for clarity and maintainability.
  - Added guidance on folder structure for datasources (local/remote) in Clean Architecture.
  - Updated changelog to reflect all recent CLI and UX improvements.


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
