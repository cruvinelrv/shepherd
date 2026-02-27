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
  parser.addCommand('gitrecover');
  parser.addCommand('auto-update');
  parser.addCommand('help');
  parser.addCommand('init');
  parser.addCommand('version');
  parser.addCommand('about');
  parser.addCommand('pull');

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

  // Groups for interactive menus
  parser.addCommand('domains');
  parser.addCommand('deploy');
  parser.addCommand('tools');

  return parser;
}
