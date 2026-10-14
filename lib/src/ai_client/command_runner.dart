import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// What a command the AI proposed did.
class CommandResult {
  final String command;
  final int exitCode;
  final bool timedOut;

  /// The end of what it printed (stdout and stderr together).
  final String tail;

  const CommandResult(this.command, this.exitCode, this.tail,
      {this.timedOut = false});

  bool get ok => exitCode == 0 && !timedOut;
}

typedef StartProcess = Future<Process> Function(
    String executable, List<String> arguments,
    {String? workingDirectory});

Future<Process> _start(String executable, List<String> arguments,
        {String? workingDirectory}) =>
    Process.start(executable, arguments, workingDirectory: workingDirectory);

/// Runs a command line in the user's shell, showing its output live and keeping
/// the last [tailChars] of it. The command gets no input (stdin is closed), so one
/// that asks a question fails instead of hanging.
class CommandRunner {
  final StartProcess start;
  final Duration timeout;
  final int tailChars;
  final void Function(String) write;

  CommandRunner({
    StartProcess? start,
    this.timeout = const Duration(minutes: 10),
    this.tailChars = 4000,
    void Function(String)? write,
  })  : start = start ?? _start,
        write = write ?? stdout.write;

  Future<CommandResult> run(String command, String cwd) async {
    final Process process;
    try {
      process = Platform.isWindows
          ? await start('powershell', ['-NoProfile', '-Command', command],
              workingDirectory: cwd)
          : await start('/bin/sh', ['-c', command], workingDirectory: cwd);
    } catch (e) {
      return CommandResult(command, 127, '$e');
    }
    final tail = StringBuffer();
    void keep(String s) {
      write(s);
      tail.write(s);
    }

    unawaited(process.stdin.close().catchError((_) {}));
    final pumps = [
      process.stdout.transform(utf8.decoder).forEach(keep),
      process.stderr.transform(utf8.decoder).forEach(keep),
    ];
    var timedOut = false;
    final timer = Timer(timeout, () {
      timedOut = true;
      process.kill();
    });
    final code = await process.exitCode;
    timer.cancel();
    await Future.wait(pumps).catchError((_) => <void>[]);
    final all = tail.toString();
    return CommandResult(
      command,
      code,
      all.length > tailChars ? all.substring(all.length - tailChars) : all,
      timedOut: timedOut,
    );
  }
}
