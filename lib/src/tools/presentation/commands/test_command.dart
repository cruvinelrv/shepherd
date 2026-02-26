import 'package:args/args.dart';
import '../../domain/services/test_generation_service.dart';

/// Test command implementation for generating Maestro flows
Future<void> runTestCommand(List<String> args) async {
  final parser = ArgParser();
  parser.addCommand('gen').addOption('story', abbr: 's');

  try {
    final results = parser.parse(args);
    final subcommand = results.command?.name;

    if (subcommand == null) {
      _printTestHelp();
      return;
    }

    switch (subcommand) {
      case 'gen':
        final storyId = results.command?['story'] as String?;
        final service = TestGenerationService();
        await service.generateFlows(storyId: storyId);
        break;
      default:
        _printTestHelp();
    }
  } catch (e) {
    _printTestHelp();
  }
}

void _printTestHelp() {
  print('Shepherd Test Commands:');
  print(
      '  gen [--story <id>]   Generate Maestro flows from @ShepherdTag annotations');
  print('  help                 Show this help');
}
