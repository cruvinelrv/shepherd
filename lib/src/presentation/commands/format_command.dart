import 'dart:io';

/// Runs Dart's formatter on the project root.
Future<void> runFormatCommand(List<String> args) async {
  print('Running Dart formatter (dart format)...');
  final result = await Process.run('dart', ['format', ...args]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode == 0) {
    print('\x1B[32mFormatting completed successfully.\x1B[0m');
  } else {
    print('\x1B[31mFormatting encountered issues.\x1B[0m');
  }
}
