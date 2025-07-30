void printShepherdHelp() {
  print('''
Shepherd CLI - Domain-Driven Project Management

Usage: shepherd <group>
       shepherd help
       shepherd init
       shepherd version
       shepherd about

Global options:
  -h, --help        Show this help menu

Run one of the following to open an interactive menu:
  shepherd domains      Manage and analyze project domains
  shepherd config       Configure domains and CLI settings
  shepherd deploy       Deployment and release tools
  shepherd tools        Utilities for project maintenance
  shepherd init         Guided project initialization

shepherd help          Show this help menu
shepherd version       Show the current Shepherd CLI version
shepherd about         Show information about the Shepherd package
Each group menu will present available actions for you to select.

You can also run utility commands directly, for example:
  shepherd clean
  shepherd lint
  shepherd format

shepherd help          Show this help menu
shepherd version       Show the current Shepherd CLI version

Examples:
  shepherd init
  shepherd domains
  shepherd config
  shepherd deploy
  shepherd tools
  shepherd clean
  shepherd lint
  shepherd format
  shepherd help
  shepherd version
  shepherd about
''');
}
