import 'dart:io';

/// Runs Dart's linter on the project root.
Future<void> runLinterCommand(List<String> args) async {
  print('Running Dart linter (dart analyze)...');
  final result = await Process.run('dart', ['analyze', ...args]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode == 0) {
    print('\x1B[32mLinter finished with no issues.\x1B[0m');
  } else {
    print('\x1B[31mLinter found issues.\x1B[0m');
  }
}
