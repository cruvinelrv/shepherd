# CHANGELOG [0.6.6]

## 0.6.6 - 2025-12-15

- Added configurable auto-update modes via `.shepherd/config.yaml`.
- New update modes: `notify` (default, shows notification), `prompt` (asks user to update), `silent` (disables checks).
- Implemented interactive update prompt that can automatically execute `dart pub global activate shepherd` if user confirms.

# CHANGELOG [0.6.5]

## 0.6.5 - 2025-12-15

- Fixed a bug where the previous `CHANGELOG.md` content was not being archived to `dev_tools/changelog_history.md` when using the "update" mode in deploy or changelog commands.
- Refactored `deploy` command to use the unified `ChangelogService` logic, ensuring consistent behavior and proper history preservation across all changelog operations.

# CHANGELOG [0.6.4]

## 0.6.4 - 2025-11-19

- Centralized and improved the version detection logic: Shepherd now always tries the root pubspec.yaml first, then automatically falls back to the first microfrontend if needed, for all update flows.
- All related comments and documentation are now in English for better maintainability.

# CHANGELOG [0.6.3]

## 0.6.3 - 2025-11-19

- Fixed the update command to correctly fallback to the first microfrontend's pubspec.yaml when the root pubspec.yaml is missing, preventing errors in microfrontends environments.
- Now the changelog version is always set, as long as a pubspec.yaml exists in the root or in the first microfrontend.

# CHANGELOG [0.6.2]

## 0.6.2 - 2025-11-19

- Improved version detection for microfrontends: if there is no pubspec.yaml in the root, Shepherd now automatically uses the version from the first registered microfrontend.
- Ensured changelog versioning works correctly in microfrontends environments.

# CHANGELOG [0.6.1]

## 0.6.1 - 2025-11-18

- Fixed a bug where the CLI version was not displayed version correctly in some scenarios.

# CHANGELOG [0.6.0]

## 0.6.0 - 2025-11-18

- Improved the changelog type selection prompt: now provides clear English explanations, automatic suggestions based on branch name, and a help option for user guidance.
- Enhanced user experience for changelog and deploy commands, reducing confusion between "update" and "change" options.
- Fixed path/case issues when copying the changelog from a reference branch, ensuring robust operation in all environments.
- General code cleanups and minor bug fixes.

# CHANGELOG [0.5.9]

## 0.5.9 - 2025-11-18

- Shepherd version command now always displays the CLI version from a constant, regardless of the current project.
- Improved internal code organization and fixed minor issues with command registration.

# CHANGELOG [0.5.8]

## 0.5.8 - 2025-11-18

- Refactored changelog copy logic to always use `git show` instead of `git checkout`, ensuring compatibility and reliability across all project structures.
- Fixed issues where changelog operations could fail in microfrontends due to file existence discrepancies between branches.
- Improved error handling and user feedback when copying the changelog from the reference branch.
- General code cleanups and documentation updates.

# CHANGELOG [0.5.7]

## 0.5.7 - 2025-11-18

- Ensured that `CHANGELOG.md` is managed only at the project root, even in microfrontends contexts.
- Fully reviewed and standardized the logic for changelog update and copy in both `deploy` and `changelog` commands.
- Improved robustness and clarity of the deploy and changelog flows.
- Minor fixes and message adjustments for better predictability and maintainability.

# CHANGELOG [0.5.6]

## 0.5.6 - 2025-11-18

- Standardized the method for copying CHANGELOG.md from the reference branch using git checkout in both deploy and changelog commands.
- Improved code consistency and maintainability across CLI commands.
- Minor bug fixes and usability improvements.

# CHANGELOG [0.5.5]

## 0.5.5 - 2025-11-12

- Bugs general fixes

## 0.5.4 - 2025-11-12

- Added gitrecover command: interactive interface, branch and date selection, commit summary, confirmation, and automatic changelog saving.
- User experience improvements for deploy and changelog commands.
- Bug fixes in changelog generation.

## 0.5.3 - 2025-11-12

- **Changelog update reliability:** Improved the update option in the deploy process to ensure the changelog is copied from the reference branch and the header is updated correctly, without fetching commits.
- **Microfrontends safety:** Added safeguards to prevent changelog overwrites or errors in microfrontends environments during deploy update.
- **Internationalization:** Standardized all code comments to English for better maintainability and collaboration.
- **Bug fixes and refactoring:** General code cleanups and minor bug fixes to improve stability and code quality.

## 0.5.2 - 2025-11-12

**Improved deploy process:** Deploy now allows choosing between "change" or "update" options for the changelog, making the workflow more flexible and automated.
**Changelog header update guarantee:** The changelog header is automatically updated after the file is copied when choosing the update option in the deploy process.
**General fixes:** Code adjustments and cleanups for better organization and standardization.

## 0.5.1 - 2025-10-10
- **Fixed Shepherd changelog and deploy process**: Implemented comprehensive improvements to the changelog system including history preservation, version detection, enhanced formatting with hash/author/date, microfrontends support, and deploy workflow optimization with direct step-by-step execution.

## 0.5.0 - 2025-10-07
- **Fixed Init Command**: Restored full functionality to `shepherd init` command that was broken due to missing routing in CLI runner.
- **Fixed Deploy Command**: Restored full functionality to `shepherd deploy` command that was broken due to missing routing in CLI runner.
- **Enhanced Deploy Implementation**: Complete overhaul of deploy command to execute step-by-step deployment process directly without interactive menus.
- **Streamlined Deploy Workflow**: Deploy command now runs automatic step-by-step process including version updates, changelog generation, and PR creation prompts.
- **Improved CLI Routing**: Fixed systematic CLI routing issues affecting multiple commands (init, deploy, clean) by adding proper switch cases in shepherd_runner.dart.
- **Command Standardization**: Implemented consistent command wrapper pattern for all CLI commands with standardized argument handling.
- **Direct Deploy Execution**: `shepherd deploy` now executes deployment workflow directly instead of showing interactive menu, making it more efficient for CI/CD usage.
- **Better User Experience**: Simplified deployment process with streamlined prompts and automatic progression through deployment steps.

## 0.4.9 - 2025-10-07
- **Fixed Clean Command**: Restored full functionality to `shepherd clean` command that was broken due to missing routing in CLI runner.
- **Enhanced Clean Implementation**: Complete rewrite of clean command with robust project detection, recursive cleaning, and comprehensive cleanup operations.
- **Improved Clean Features**: Added support for both global cleaning (`shepherd clean`) and project-specific cleaning (`shepherd clean project`) with enhanced visual feedback.
- **Better Error Handling**: Improved error handling and user feedback during clean operations with detailed status reporting and emoji indicators.
- **Comprehensive Cleanup**: Clean command now removes `pubspec.lock`, `build/`, `.dart_tool/` directories and runs `flutter clean` + `flutter pub get` automatically.
- **Multi-Project Support**: Enhanced support for cleaning multiple projects and microfrontends in a single command execution.

## 0.4.8 - 2025-10-07
- **Complete DDD Architecture Implementation**: Implemented comprehensive Domain-Driven Design architecture for changelog service with proper separation of domain, data, and presentation layers.
- **Enhanced Feature Toggle System**: Complete refactoring of feature toggle commands to use clean DDD patterns with enhanced database support and enterprise fields (team, activity, prototype, versions).
- **Full English Internationalization**: Translated all Portuguese user-facing text to English across feature toggle commands, menus, and user prompts for international compatibility.
- **Improved CLI Routing**: Fixed command routing system in shepherd_runner.dart to properly handle `dart run shepherd changelog` and other commands.
- **Professional User Interface**: Standardized all user interactions with consistent English messaging, field labels, and status indicators.
- **Enterprise Field Support**: Added comprehensive support for enterprise-level feature toggle fields including team assignments, activity tracking, and prototype management.
- **Enhanced Import/Export**: Improved DynamoDB Terraform import/export functionality with configurable field mapping and validation.
- **Database Architecture**: Implemented robust enhanced feature toggle database with full CRUD operations and migration support from legacy systems.
- **Configuration Management**: Added advanced import field configuration system with predefined templates and custom mapping capabilities.
- **Backward Compatibility**: Maintained full compatibility with existing feature toggle data while providing migration paths to enhanced system.

## 0.4.7 - 2025-09-03
- Automatic synchronization: now, whenever any essential YAML file contains data, `shepherd pull` is executed automatically to ensure `shepherd.db` is always up-to-date with YAML sources.
- Improved logic for database and YAML sync: prevents outdated information by always prioritizing YAML content when present.
- The `user_active.yaml` file is now generated automatically based on the selection of owners in `domains.yaml`.
- Minor bug fixes and code cleanups.

## 0.4.6 - 2025-09-03
- Improved user registration flow in `shepherd pull` (separate prompts for first name and last name).
- When running the shepherd command, if the user_active.yaml file does not exist, suggest creating a default user or registering a new one from scratch.

## 0.4.5 (2025-09-01)

- Refactored changelog update flow to use a single prompt for the base branch, regardless of project type.
- Minor bug fixes and code cleanup.

## 0.4.4 - 2025-09-01
- Improved changelog flow: base branch is now requested only once for both simple projects and microfrontends, preventing duplicate prompts and errors.
- Unified logic for changelog updates, ensuring a smoother experience in all project types.
- Minor bug fixes and code cleanups.

## 0.4.3 - 2025-09-01
- Improved the shepherd pull flow: now the database is created and populated from YAML files if missing, without triggering project initialization.
- Enhanced validation: shepherd pull no longer requires shepherd.db to exist beforehand, making onboarding and sync more robust.
- Minor bug fixes and code cleanups for a smoother CLI experience.

## 0.4.2 - 2025-08-29
- Restored branch name registration in the changelog before each group of commits.
- Commits are now listed with a dash (`- `) for improved readability.
- Minor code and documentation cleanups.

## 0.4.1 - 2025-08-28
- Refactored changelog service: removed all debug prints and ensured clean output for production use.
- Centralized environment branch validation logic in a dedicated function (`validateEnvironmentBranch`), improving maintainability and clarity.
- The changelog update flow now blocks updates on environment branches, with clear messaging and no duplicate success messages.
- Translated all code comments and user-facing messages to English for internationalization and consistency.
- Improved modularization: separated logic for simple projects and microfrontends, making the codebase easier to extend and maintain.
- Minor bug fixes and code cleanup for robustness.

## 0.4.0 - 2025-08-28
- The changelog now prompts the user to specify the base branch (e.g., main, develop) when updating, making the workflow flexible for any team or context.
- Commit filtering improved: only direct semantic commits (refactor:, feat:, fix:) exclusive to the current branch (compared to the specified base) are registered.
- Removed dependency on shepherd.yaml for base branch configuration; the entire flow is now handled via user input.
- Ensured the base branch prompt is integrated into all Shepherd commands that update the changelog, including deploy.
- Refactored and centralized commit regex for greater clarity and maintainability.

## 0.3.9 - 2025-08-28
- Changelog service now strictly registers only direct semantic commits (refactor:, feat:, fix:) authored by the user, excluding all merges—even those with semantic messages.
- The release history is now fully aligned with the Conventional Commits standard and avoids noise from merged PRs.

## 0.3.8 - 2025-08-28
- Changelog service now only registers semantic commits (refactor:, feat:, fix:, tests:) authored by the current user and excludes merges.
- Release notes are now cleaner and focused on meaningful changes, following the Conventional Commits standard.

## 0.3.7 - 2025-08-28
- Centralized all commit-related regular expressions in shepherd_regex.dart for maintainability and clarity.
- Changelog service now uses ShepherdRegex for author and parent hash extraction, making commit filtering more robust and easier to maintain.

## 0.3.6 - 2025-08-28
- Changelog logic updated: now all commits are listed from the current branch, independent of any base branch (like main).
- This makes the changelog compatible with any workflow or branch naming convention, ensuring all your direct commits are captured.

## 0.3.5 - 2025-08-28
- Changelog filter improved: now uses Git commit parent hashes to technically exclude all merge commits, regardless of message content.
- Only direct commits authored by the current user are listed, making the changelog even more precise and robust.

## 0.3.4 - 2025-08-28
- Changelog commit filtering improved: now only shows commits authored by the current user in their branch.
- All merge commits (including PR merges and branch merges) are excluded from the changelog.
- Commits of type docs, chore, and style continue to be excluded for clarity.
- This ensures the changelog reflects only your direct contributions, making release notes more precise and personalized.

## 0.3.3 - 2025-08-28
- Refactored runner to act only as orchestrator, delegating validation and initialization to services.
- Centralized essential file validation and initialization in PathValidatorService.
- Fixed YAML file creation: all essential files are now created inside the .shepherd folder.
- Improved pull command: now always creates/synchronizes YAML files in .shepherd and updates the database accordingly.
- Enhanced SQLite inspection: CLI now allows viewing structure and data of all tables in shepherd.db.
- Modularized and cleaned up code for better maintainability and robustness.
- Improved error handling and feedback for missing essential files.
- Updated documentation and changelog logic for clarity and consistency.

## 0.3.2 - 2025-08-28
- Centralized active user logic in SyncController; removed all runner references to hasUser.
- New feature: CLI now checks for an active user and prompts to create a new user by entering details, or initializes with default values if preferred.
- Cleaned up runner logic: removed legacy variables and conditions, now only calls SyncController for user setup.
- Enhanced YAML and database consistency checks.
- Minor bug fixes and documentation updates.

## 0.3.1 - 2025-08-28
- Fixed the path for reading the .shepherd/domains.yaml file to ensure correct operation across multiple projects.

## 0.3.0 - 2025-08-27
- Shepherd now creates and uses the shepherd.db database and YAML files exclusively inside the .shepherd folder.
- The initialization flow has been improved: the interactive menu only shows the "project already initialized" warning if project.yaml contains valid id and name.
- Improvements in validation and consistency of YAML files and the database.
- Adjustments and refactoring for greater robustness, clarity, and user experience.
- Created a new registration for squad management.
- ShepherdCLI prepare code structure for display an interactive and visual Dashboard.
- The changelog.md now includes user commits, excluding docs, style, and chore commits, following the semantic commit standard.
## 0.2.9 - 2025-08-08
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
