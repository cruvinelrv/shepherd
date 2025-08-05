class DirectCommandsMenu {
  static void printShepherdHelp() {
    print('''
Shepherd CLI Help
-----------------

Usage:
  shepherd <command> [options]

Common commands:
  init         Initialize a new Shepherd project
  pull         Import project configuration from YAML
  analyze      Analyze project domains
  clean        Clean all projects/microfrontends
  config       Configure domains and owners
  add-owner    Add owner to an existing domain
  export-yaml  Export domains and owners to YAML
  changelog    Update changelog automatically
  help         Show this help message
  about        Show information about Shepherd

For detailed help on a command, use 'shepherd <command> --help'.
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
