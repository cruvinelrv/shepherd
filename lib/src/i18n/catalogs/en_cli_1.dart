// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> enCli1 = {
  'install.homebrew': 'Homebrew (shepherd_cli)',
  'install.script': 'install script (curl / PowerShell)',
  'install.studio': 'bundled with Shepherd Studio',
  'install.source': 'source code (dart run)',
  'install.unknown': 'unknown',
  'model.gone':
      'This model is no longer available to your account. Type "/model" (or `shepherd ai model`) and pick another one from the list.',
  'sync.conflict': '❌ Sync conflict!',
  'sync.newer':
      'The cloud has newer information (cloud: {server} > local: {local}).',
  'sync.pull':
      'Run `git pull` to get the latest version before running `shepherd gen` again.',
  'update.not_pub': 'this installation is not from pub.dev',
  'update.header': 'Shepherd CLI {version} — installed via: {method}',
  'update.no_check':
      'Could not check the latest version (no internet?). Try again later.',
  'update.up_to_date': '✅ You are already on the latest version ({version}).',
  'update.available': '📦 New version available: {current} → {newest}',
  'update.news': '   What\'s new: {url}',
  'update.studio':
      'This CLI ships inside Shepherd Studio: update Studio to get the new version.',
  'update.source':
      'You are running from source: update the repository (git pull && dart pub get).',
  'update.unknown':
      'I don\'t know how this CLI was installed. Use the command that matches your case:',
  'update.to_update': 'To update, run:',
  'update.brew_lag':
      'If Homebrew says it is already up to date, the formula has not received {newest} yet: try again later.',
  'update.running': '⏳ Updating...',
  'update.done': '✅ Done. Open a new terminal to use {newest}.',
  'update.failed':
      '❌ The update failed (code {code}). Run it manually: {command}',
  'update.ask': '\nUpdate now? [y/N]: ',
  'clean.home1': '⚠️ You are in your home directory (~).',
  'clean.home2':
      '👉 Go to your project/workspace folder before running clean (e.g. cd dev/my_project).\n',
  'pr.gh_missing':
      'GitHub CLI (gh) not found. Install it from Shepherd\'s tools menu.',
  'pr.az_login':
      'You are not logged in to the Azure CLI. The PR will be saved in the database to be sent later.',
  'pr.az_saved':
      'PR saved in the database. You can resend it when you are logged in to Azure.',
  'toggle.exists': 'A Feature Toggle named "{name}" already exists.',
  'toggle.not_found': 'Feature toggle not found with id: {id}',
  'cl.start': '🧹 Starting Shepherd Clean...\n',
  'cl.ws_project': '📍 Workspace project detected: "{name}"',
  'cl.mf_project': '📍 Microfrontend detected: "{name}"',
  'cl.target': '📍 Target directory: {path}\n',
  'cl.target_missing': '❌ Target directory or project not found: {arg}\n',
  'cl.current_only': '📍 Cleaning the current project only ({path})...',
  'cl.no_pubspec_here':
      '❌ No pubspec.yaml found in the current directory ({path}).',
  'cl.manifest':
      '🏢 Workspace manifest detected: "{name}" ({n} registered projects)',
  'cl.mf_manifest':
      '🧩 Microfrontends manifest detected ({n} registered microfrontends)',
  'cl.searching': '🔍 Searching for pubspec.yaml files safely...',
  'cl.none_found': '❌ No pubspec.yaml files found in "{path}".',
  'cl.found': '📦 Found {n} project(s) to clean',
  'cl.cleaning': '--- 🧽 Cleaning: {name} ({path}) ---',
  'cl.rm_lock': '🗑️  Removed pubspec.lock',
  'cl.rm_lock_fail': '⚠️  Could not remove pubspec.lock: {e}',
  'cl.rm_build': '🗑️  Removed build/ directory',
  'cl.rm_build_fail': '⚠️  Could not remove build/: {e}',
  'cl.rm_dart_tool': '🗑️  Removed .dart_tool/ directory',
  'cl.rm_dart_tool_fail': '⚠️  Could not remove .dart_tool/: {e}',
  'cl.flutter_clean': '🔧 Running flutter clean...',
  'cl.flutter_clean_ok': '✅ Flutter clean completed',
  'cl.flutter_clean_issues': '⚠️  Flutter clean had issues: {e}',
  'cl.flutter_clean_fail': '⚠️  Could not run flutter clean: {e}',
  'cl.flutter_get': '📥 Running flutter pub get...',
  'cl.dart_get': '📥 Running dart pub get...',
  'cl.deps_ok': '✅ Dependencies restored',
  'cl.get_issues': '⚠️  pub get had issues: {e}',
  'cl.flutter_get_fail': '⚠️  Could not run pub get: {e}',
  'cl.dart_get_fail': '⚠️  Could not run dart pub get: {e}',
  'cl.done': '🎉 Clean process completed for {n} project(s)!',
  'qi.title': '🐑 New Shepherd workspace',
  'qi.intro':
      'A workspace is a folder with the settings in .shepherd/; each project inside it has its own git. A few questions, each with a default (Enter).',
  'qi.already': 'A Shepherd workspace is already set up in this folder.',
  'qi.continue_anyway': 'Set it up again and overwrite its settings? [y/N]: ',
  'qi.cancelled': 'Nothing was changed.',
  'qi.ask_name': 'Workspace name',
  'qi.bad_name': 'The name cannot be empty or contain / or \\.',
  'qi.new_folder':
      'Create a new folder "{name}" here and set it up there? [Y/n] (n = use this folder): ',
  'qi.ask_user': 'Your name',
  'qi.ask_email': 'Your email',
  'qi.need_user': 'A name is needed. Use --user "First Last".',
  'qi.ask_repo': 'Where will the code live? (github / azure / later)',
  'qi.bad_repo': 'Type github, azure or later.',
  'qi.ask_github': 'Your GitHub username (for pull requests, Enter to skip)',
  'qi.done': '✅ Workspace "{name}" is ready.',
  'qi.sum_where': 'Folder:       {path}',
  'qi.sum_user': 'You:          {user} <{email}>',
  'qi.sum_env':
      'Environment:  PRD → {trunk} (trunk based development: one branch)',
  'qi.sum_repo': 'Repository:   {repo}',
  'qi.repo_later': 'not set yet (pull requests off)',
  'qi.change':
      'Change anything later in .shepherd/ (environments.yaml, config.yaml) or with `shepherd config`.',
  'login.global':
      '🔑 This login works in every folder (saved in ~/.shepherd/session.yaml).',
  'login.no_folder':
      'No workspace in this folder, so there is no project to link. Run `shepherd init` (or `shepherd` and pick an option) here when you want one.',
  'shell.h_system':
      'Runs a system command (ls, cat, git…); `!` before any other one',
  'mcp.none_global':
      'ℹ️  No MCP server configured in the workspace or globally.',
  'mcp.edit': 'Edit the file {file} to add MCP servers.',
  'mcp.example': 'Example:',
  'mcp.configured': '🔌 Configured MCP servers ({n}):',
  'mcp.command_label': 'command',
  'mcp.connecting': '    Connecting and fetching tools... ',
  'mcp.ok_tools': '({ms}ms, {n} tools)',
};
