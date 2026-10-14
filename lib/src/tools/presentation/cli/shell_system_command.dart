import 'dart:io';

/// Everyday terminal commands the shell runs itself, instead of sending them to
/// the AI as a question (the AI cannot see the disk). Anything else can be run
/// with a leading `!`, e.g. `!rm -r build`.
const systemCommands = {
  'ls',
  'll',
  'la',
  'dir',
  'cat',
  'head',
  'tail',
  'tree',
  'echo',
  'mkdir',
  'touch',
  'which',
  'git',
};

/// The line to run when [trimmed] is a system command or starts with `!`,
/// null when it is for Shepherd.
String? systemCommandLine(String trimmed) {
  if (trimmed.startsWith('!')) {
    final rest = trimmed.substring(1).trim();
    return rest.isEmpty ? null : rest;
  }
  final first = trimmed.split(RegExp(r'\s+')).first;
  if (!systemCommands.contains(first)) return null;
  return switch (first) {
    'll' => 'ls -l${trimmed.substring(2)}',
    'la' => 'ls -la${trimmed.substring(2)}',
    _ => trimmed,
  };
}

/// Runs [line] in the user's shell, with its output going straight to the terminal.
/// Returns the exit code.
Future<int> runSystemCommand(String line) async {
  final process = Platform.isWindows
      ? await Process.start('cmd', ['/c', line],
          mode: ProcessStartMode.inheritStdio)
      : await Process.start('/bin/sh', ['-c', line],
          mode: ProcessStartMode.inheritStdio);
  return process.exitCode;
}
