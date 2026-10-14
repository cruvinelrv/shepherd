import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// What a command the AI proposed did.
class CommandResult {
  final String command;
  final int exitCode;
  final bool timedOut;

  /// The user pressed Ctrl+C: the command was stopped on purpose (a server such as
  /// `flutter run` is meant to be stopped this way).
  final bool interrupted;

  /// How long it ran.
  final Duration took;

  /// The end of what it printed (stdout and stderr together).
  final String tail;

  const CommandResult(this.command, this.exitCode, this.tail,
      {this.timedOut = false,
      this.interrupted = false,
      this.took = Duration.zero});

  bool get ok => (exitCode == 0 || interrupted) && !timedOut;
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

  /// Ctrl+C; replaced in tests.
  final Stream<Object?> Function() sigint;

  CommandRunner({
    StartProcess? start,
    this.timeout = const Duration(minutes: 10),
    this.tailChars = 4000,
    void Function(String)? write,
    Stream<Object?> Function()? sigint,
  })  : start = start ?? _start,
        write = write ?? stdout.write,
        sigint = sigint ?? (() => ProcessSignal.sigint.watch());

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
    var interrupted = false;
    final began = DateTime.now();
    final signal = sigint().listen((_) {
      interrupted = true;
      killTree(process.pid);
    });
    final timer = Timer(timeout, () {
      timedOut = true;
      killTree(process.pid);
    });
    final code = await process.exitCode;
    timer.cancel();
    await signal.cancel();
    // A grandchild that kept the pipes open must not hold the chat.
    await Future.wait(pumps)
        .timeout(const Duration(seconds: 2))
        .catchError((_) => <void>[]);
    final all = tail.toString();
    return CommandResult(
      command,
      code,
      all.length > tailChars ? all.substring(all.length - tailChars) : all,
      timedOut: timedOut,
      interrupted: interrupted,
      took: DateTime.now().difference(began),
    );
  }
}

/// Stops [pid] and everything it started: the shell that runs a command is not the
/// program that matters (`flutter run`, a dev server), so killing only the shell
/// would leave that program running.
void killTree(int pid) {
  if (Platform.isWindows) {
    Process.runSync('taskkill', ['/T', '/F', '/PID', '$pid']);
    return;
  }
  void walk(int parent) {
    final r = Process.runSync('pgrep', ['-P', '$parent']);
    for (final line in '${r.stdout}'.split('\n')) {
      final child = int.tryParse(line.trim());
      if (child != null) walk(child);
    }
    Process.killPid(parent);
  }

  try {
    walk(pid);
  } catch (_) {
    Process.killPid(pid);
  }
}
