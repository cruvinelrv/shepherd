import 'package:args/args.dart';
import '../../domain/services/tag_generation_service.dart';

/// Tag command implementation for generating tag wrapper classes
Future<void> runTagCommand(List<String> args) async {
  final parser = ArgParser();
  parser.addCommand('gen').addOption('story', abbr: 's');

  try {
    final results = parser.parse(args);
    final subcommand = results.command?.name;

    if (subcommand == null) {
      _printTagHelp();
      return;
    }

    switch (subcommand) {
      case 'gen':
        final storyId = results.command?['story'] as String?;
        final service = TagGenerationService();
        await service.scanAndGenerate(storyId: storyId);
        break;
      default:
        _printTagHelp();
    }
  } catch (e) {
    _printTagHelp();
  }
}

void _printTagHelp() {
  print('Shepherd Tag Commands:');
  print(
      '  gen [--story <id>]   Generate Tag Wrapper classes and auto-register stories from code');
  print('  help                 Show this help');
}
