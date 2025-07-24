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
