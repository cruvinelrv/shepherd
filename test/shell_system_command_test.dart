import 'package:shepherd/src/tools/presentation/cli/shell_system_command.dart';
import 'package:test/test.dart';

void main() {
  test('everyday terminal commands run in the system', () {
    expect(systemCommandLine('ls'), 'ls');
    expect(systemCommandLine('ls -la src'), 'ls -la src');
    expect(systemCommandLine('git status'), 'git status');
    expect(systemCommandLine('ll'), 'ls -l');
    expect(systemCommandLine('la src'), 'ls -la src');
    expect(systemCommandLine('cat a.txt | head -2'), 'cat a.txt | head -2');
  });

  test('! runs anything, and an empty ! is nothing', () {
    expect(systemCommandLine('!rm -r build'), 'rm -r build');
    expect(systemCommandLine('!  flutter doctor'), 'flutter doctor');
    expect(systemCommandLine('!'), isNull);
  });

  test('a question or a Shepherd command is not a system command', () {
    expect(systemCommandLine('list the files of lib'), isNull);
    expect(systemCommandLine('clean'), isNull);
    expect(systemCommandLine('lsof'), isNull);
    expect(systemCommandLine('explain @lib/main.dart'), isNull);
  });
}
