import 'package:test/test.dart';
import 'package:shepherd/src/tools/domain/entities/shell_session_entity.dart';
import 'package:shepherd/src/tools/data/models/shell_session_model.dart';
import 'package:shepherd/src/tools/presentation/cli/shepherd_shell.dart';

void main() {
  group('ShepherdShell.parseCommandLine', () {
    test('parses simple words into argument list', () {
      final args = ShepherdShell.parseCommandLine('clean project');
      expect(args, equals(['clean', 'project']));
    });

    test('parses arguments with double quotes preserving spaces', () {
      final args = ShepherdShell.parseCommandLine('ai "como criar testes unitários?" --scope workspace');
      expect(args, equals(['ai', 'como criar testes unitários?', '--scope', 'workspace']));
    });

    test('parses arguments with single quotes', () {
      final args = ShepherdShell.parseCommandLine("story add 'Autenticação com Biometria'");
      expect(args, equals(['story', 'add', 'Autenticação com Biometria']));
    });

    test('returns empty list for empty or whitespace-only input', () {
      expect(ShepherdShell.parseCommandLine(''), isEmpty);
      expect(ShepherdShell.parseCommandLine('   '), isEmpty);
    });

    test('handles flags with dashes and options', () {
      final args = ShepherdShell.parseCommandLine('flow -p minor --interactive');
      expect(args, equals(['flow', '-p', 'minor', '--interactive']));
    });
  });

  group('ShellSessionEntity', () {
    test('reports hasAiConfigured correctly', () {
      const entityWithoutAi = ShellSessionEntity(
        projectName: 'shepherd',
        isAuthenticated: false,
      );
      expect(entityWithoutAi.hasAiConfigured, isFalse);

      const entityWithAi = ShellSessionEntity(
        projectName: 'shepherd',
        aiProvider: 'gemini',
        aiModel: 'gemini-3.8-flash',
        isAuthenticated: true,
      );
      expect(entityWithAi.hasAiConfigured, isTrue);
    });
  });

  group('ShellSessionModel', () {
    test('loadFromWorkspace resolves project name from current directory without error', () {
      final session = ShellSessionModel.loadFromWorkspace();
      expect(session.projectName, isNotEmpty);
    });
  });
}
