import 'dart:async';
import 'dart:io';

import 'package:shepherd/src/ai_client/command_runner.dart';
import 'package:shepherd/src/ai_client/rpc_client.dart';
import 'package:shepherd/src/ai_client/terminal_render.dart';
import 'package:test/test.dart';

void main() {
  final posix = !Platform.isWindows;

  group('CommandRunner', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('cmd_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('runs in the folder, shows the output live and keeps its end',
        () async {
      final shown = StringBuffer();
      final r = await CommandRunner(write: shown.write)
          .run('pwd; echo out; echo err 1>&2', dir.path);
      expect(r.ok, isTrue);
      expect(r.exitCode, 0);
      expect(shown.toString(),
          allOf(contains('out'), contains('err'), contains(p(dir))));
      expect(r.tail, contains('out'));
    }, skip: !posix);

    test('a failing command reports its exit code', () async {
      final r =
          await CommandRunner(write: (_) {}).run('echo bad; exit 3', dir.path);
      expect(r.ok, isFalse);
      expect(r.exitCode, 3);
      expect(r.tail, contains('bad'));
    }, skip: !posix);

    test('only the end of a long output is kept', () async {
      final r = await CommandRunner(write: (_) {}, tailChars: 50)
          .run('for i in \$(seq 1 200); do echo line\$i; done', dir.path);
      expect(r.tail.length, lessThanOrEqualTo(50));
      expect(r.tail, contains('line200'));
      expect(r.tail, isNot(contains('line1\n')));
    }, skip: !posix);

    test('a command that waits for input does not hang: stdin is closed',
        () async {
      final r = await CommandRunner(
              write: (_) {}, timeout: const Duration(seconds: 20))
          .run('read answer; echo got:\$answer', dir.path);
      expect(r.timedOut, isFalse);
      expect(r.tail, contains('got:'));
    }, skip: !posix);

    test('too slow: stopped', () async {
      final r = await CommandRunner(
              write: (_) {}, timeout: const Duration(milliseconds: 300))
          .run('sleep 5', dir.path);
      expect(r.timedOut, isTrue);
      expect(r.ok, isFalse);
    }, skip: !posix);

    test('Ctrl+C stops a command that never ends (a server) and says so',
        () async {
      final ctrlC = StreamController<Object?>();
      final shown = StringBuffer();
      final running = CommandRunner(
              write: shown.write,
              sigint: () => ctrlC.stream,
              timeout: const Duration(seconds: 30))
          .run('echo up; sleep 30', dir.path);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      ctrlC.add(null);
      final r = await running.timeout(const Duration(seconds: 10));
      expect(r.interrupted, isTrue);
      expect(r.ok, isTrue,
          reason: 'stopping a server on purpose is not a failure');
      expect(r.timedOut, isFalse);
      expect(r.tail, contains('up'));
      expect(r.took, lessThan(const Duration(seconds: 10)));
    }, skip: !posix);

    test('a program that cannot start is a result, not a crash', () async {
      final r = await CommandRunner(
          write: (_) {},
          start: (e, a, {workingDirectory}) async =>
              throw ProcessException(e, a)).run('x', dir.path);
      expect(r.exitCode, 127);
    });
  });

  test(
      'the renderer collects the proposed commands of a turn and forgets them on the next',
      () {
    final r = TurnRenderer(out: StringBuffer(), tty: false)..startTurn(1);
    r.handle(const RpcNotification('commands/proposal', {
      'requestId': 1,
      'proposalId': 'c0',
      'command': 'flutter create app',
      'cwd': '/w',
      'risky': false,
      'before': true,
    }));
    r.handle(const RpcNotification('commands/proposal', {
      'requestId': 1,
      'proposalId': 'c1',
      'command': 'rm -rf build',
      'cwd': '/w',
      'risky': true,
      'before': true,
    }));
    expect(r.commands.map((c) => c.command),
        ['flutter create app', 'rm -rf build']);
    expect(r.commands[0].risky, isFalse);
    expect(r.commands[1].risky, isTrue);
    expect(r.commands[0].before, isTrue);
    r.startTurn(2);
    expect(r.commands, isEmpty);
  });
}

String p(Directory d) => d.resolveSymbolicLinksSync();
