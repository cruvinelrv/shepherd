import 'package:args/args.dart';

ArgParser buildShepherdArgParser() {
  return ArgParser()
    ..addCommand('analyze')
    ..addCommand('clean')
    ..addCommand('config')
    ..addCommand('list')
    ..addCommand('delete')
    ..addCommand('add-owner')
    ..addCommand('export-yaml')
    ..addCommand('changelog')
    ..addCommand('help');
}
