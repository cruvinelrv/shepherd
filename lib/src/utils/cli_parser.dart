import 'package:args/args.dart';

ArgParser buildShepherdArgParser() {
  final parser = ArgParser();

  // Direct commands
  parser.addCommand('analyze');
  parser.addCommand('clean');
  parser.addCommand('project');
  parser.addCommand('config');
  parser.addCommand('list');
  parser.addCommand('delete');
  parser.addCommand('add-owner');
  parser.addCommand('export-yaml');
  parser.addCommand('changelog');
  final flowCommand = parser.addCommand('flow');
  flowCommand.addOption('bump',
      abbr: 'p',
      help: 'Version bump type (keep, patch, minor, major)',
      allowed: ['keep', 'patch', 'minor', 'major']);
  flowCommand.addOption('base',
      abbr: 'b',
      help:
          'Base tag/commit to compare against (default: auto-detected previous tag)');
  flowCommand.addFlag('interactive',
      abbr: 'i', help: 'Prompt for inputs if not specified', defaultsTo: true);
  flowCommand.addFlag('help',
      abbr: 'h', help: 'Show help message', negatable: false);
  parser.addCommand('gitrecover');
  parser.addCommand('auto-update');
  parser.addCommand('help');
  parser.addCommand('init');

  final loginCommand = parser.addCommand('login');
  loginCommand.addOption('apikey',
      abbr: 'a', help: 'The API Key for Shepherd Union');

  parser.addCommand('version');
  parser.addCommand('about');
  parser.addCommand('pull');
  parser.addCommand('shell');
  parser.addCommand('mcp');

  final testCommand = parser.addCommand('test');
  testCommand.addOption('story',
      abbr: 's', help: 'Story/Feature ID to generate tests for');

  final tagCommand = parser.addCommand('tag');
  tagCommand.addCommand('gen').addOption('story',
      abbr: 's', help: 'Story/Feature ID to generate tag stubs for');

  final elementCommand = parser.addCommand('element');
  elementCommand.addCommand('add');
  elementCommand.addCommand('list');

  final storyCommand = parser.addCommand('story');
  storyCommand.addCommand('add');
  storyCommand.addCommand('list');

  final taskCommand = parser.addCommand('task');
  taskCommand.addCommand('add');
  taskCommand.addCommand('list');

  final aiCommand = parser.addCommand('ai');
  aiCommand.addOption('model',
      abbr: 'm',
      defaultsTo: 'gemini-3.8-flash',
      help: 'Modelo do Gemini a ser utilizado.');
  aiCommand.addOption('scope',
      abbr: 's',
      allowed: ['project', 'workspace'],
      defaultsTo: 'project',
      help: 'project: só o diretório atual. workspace: inclui todos os '
          'projetos do .shepherd/workspace.yaml.');
  aiCommand.addCommand('config');

  // Groups for interactive menus
  parser.addCommand('domains');
  parser.addCommand('deploy');
  parser.addCommand('tools');

  return parser;
}
