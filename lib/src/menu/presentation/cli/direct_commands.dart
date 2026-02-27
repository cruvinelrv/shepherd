class DirectCommandsMenu {
  static void printShepherdHelp() {
    print('''
Shepherd CLI Help
=================

Usage:
  shepherd <command> [options]

DIRECT COMMANDS:
  init           Initialize a new Shepherd project
  pull           Import project configuration from YAML
  analyze        Analyze project domains
  export-yaml    Export domains and owners to YAML
  add-owner      Add owner to an existing domain

AUTOMATION & MAINTENANCE:
  clean          Clean all projects/microfrontends
  changelog      Update changelog automatically
  gitrecover     Recover changelog by date range
  auto-update    Configure auto-update settings
  deploy         Deploy and release management
  tag gen        Generate tag wrapper classes from annotations
  test gen       Generate Maestro tests from tags
  story <add|list> Manage user stories
  task <add|list>  Manage tasks for user stories
  element <add|list> Manage design elements (Atoms, Molecules, etc.)

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
  gitrecover     Recover changelog by date range
  auto-update    Configure auto-update settings
  deploy         Deploy and release management
  tag gen        Generate tag wrapper classes
  test gen       Generate Maestro tests
  story <add|list> Manage user stories
  task <add|list>  Manage tasks
  element <add|list> Manage design elements

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
Shepherd CLI
------------
A modular CLI and Dart package for DDD project management.
Homepage: https://shepherd.inatos.com.br
Repository: https://github.com/cruvinelrv/shepherd
Documentation: https://shepherd.inatos.com.br/docs
License: MIT
Author: Vinicius Cruvinel
''');
  }
}
