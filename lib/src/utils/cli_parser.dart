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

  // Groups for interactive menus
  parser.addCommand('domains');
  parser.addCommand('deploy');
  parser.addCommand('tools');

  return parser;
}
