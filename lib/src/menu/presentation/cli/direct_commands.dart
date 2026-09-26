class DirectCommandsMenu {
  static void printShepherdHelp() {
    print('''
Shepherd CLI Help
=================

Usage:
  shepherd <command> [options]

DIRECT COMMANDS:
  shell          Start Shepherd interactive shell (REPL)
  init           Initialize a new Shepherd project
  pull           Import project configuration from YAML
  analyze        Analyze project domains
  export-yaml    Export domains and owners to YAML
  add-owner      Add owner to an existing domain

AUTOMATION & MAINTENANCE:
  clean          Clean all projects/microfrontends
  changelog      Update changelog automatically
  flow           Run local TBD release flow (changelog + tag + push)
  gitrecover     Recover changelog by date range
  auto-update    Configure auto-update settings
  deploy         Deploy and release management
  tag gen        Generate tag wrapper classes from annotations
  test gen       Generate Maestro tests from tags
  story <add|list> Manage user stories
  task <add|list>  Manage tasks for user stories
  element <add|list> Manage design elements (Atoms, Molecules, etc.)

AI:
  ai             Send a prompt to a Gemini model (supports stdin pipes)
  ai             Run with no prompt in a real terminal for interactive chat mode
  ai --scope workspace  Include every project from .shepherd/workspace.yaml as context
  ai config      Configure the model and API key used by `shepherd ai`

INTERACTIVE MENUS (accessible via main menu):
  Run 'shepherd' without arguments to access:
    - Domains      Manage and analyze project domains
    - Config       Configure domains and CLI settings
    - Deploy       Deployment and release tools
    - Tools        Utilities for project maintenance

INFORMATION:
  help           Show this help message
  version        Show the current Shepherd CLI version
  about          Show information about Shepherd

Examples:
  shepherd shell             # Start interactive shell (REPL)
  shepherd init              # Initialize a new project
  shepherd clean             # Clean all projects
  shepherd                   # Open interactive menu
  shepherd help              # Show this help

For more details on any command, run:
  shepherd <command> --help

''');
  }

  static void printAutomationHelp() {
    print('''
Shepherd CLI Help (Automation Mode)
====================================

Usage:
  shepherd <command> [options]

AUTOMATION & MAINTENANCE:
  clean          Clean all projects/microfrontends
  changelog      Update changelog automatically
  flow           Run local TBD release flow (changelog + tag + push)
  gitrecover     Recover changelog by date range
  auto-update    Configure auto-update settings
  deploy         Deploy and release management
  tag gen        Generate tag wrapper classes
  test gen       Generate Maestro tests
  story <add|list> Manage user stories
  task <add|list>  Manage tasks
  element <add|list> Manage design elements
  ai             Send a prompt to a Gemini model (supports stdin pipes)
  ai config      Configure the model and API key used by `shepherd ai`

INFORMATION:
  help           Show this help message
  version        Show the current Shepherd CLI version
  about          Show information about Shepherd

Examples:
  shepherd clean             # Clean all projects
  shepherd changelog         # Generate/update changelog
  shepherd deploy            # Run deployment workflow
  shepherd help              # Show this help

For more details on any command, run:
  shepherd <command> --help

''');
  }

  static void printShepherdAbout() {
    print('''
Shepherd CLI v0.11.0
====================
Advanced CLI automation and productivity engine for Dart & Flutter.
Developed and maintained by Marmelotech (https://marmelotech.com.br).

Platform:      https://www.shepherdplatform.com (Crie sua conta gratuita)
Documentation: https://www.shepherdplatform.com/docs
Repository:    https://github.com/cruvinelrv/shepherd
Author:        Vinicius Cruvinel (Marmelotech)
License:       MIT
''');
  }
}
