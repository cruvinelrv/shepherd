import 'dart:async';

import 'package:shepherd/src/tools/domain/services/ai_jsonl_protocol.dart';
import 'package:shepherd/src/tools/domain/services/ai_keep_alive.dart';
import 'package:shepherd/src/tools/domain/services/ai_session_runner.dart';
import 'package:shepherd/src/tools/domain/services/ai_settings_resolver.dart';
import 'package:test/test.dart';

const _settings =
    AiResolvedSettings(provider: 'ollama', model: 'm', isLocal: true);
const _tick = Duration(milliseconds: 40);

/// A provider stub: waits [delay] before the first chunk, or never answers.
AiGenerate _slow(Duration delay,
        {List<String> chunks = const ['ok\n'], bool never = false}) =>
    (
        {required prompt,
        required provider,
        required model,
        apiKey,
        baseUrl,
        onUsage}) async* {
      if (never) {
        await Completer<void>().future; // silent forever
      }
      await Future<void>.delayed(delay);
      for (final c in chunks) {
        yield c;
      }
    };

void main() {
  group('keepAlive', () {
    test('adds a beat only while the source is quiet, then stops with it',
        () async {
      final source = Stream<int>.fromFutures([
        Future.delayed(const Duration(milliseconds: 10), () => 1),
        Future.delayed(const Duration(milliseconds: 260), () => 2),
      ]);
      final out =
          await keepAlive<int>(source, every: _tick, beat: (_) => -1).toList();
      expect(out.first, 1);
      expect(out.last, 2);
      final beats = out.where((e) => e == -1).length;
      expect(beats, inInclusiveRange(3, 7)); // ~250 ms of quiet / 40 ms
    });

    test('a chatty source gets no beats', () async {
      final source =
          Stream<int>.periodic(const Duration(milliseconds: 10), (i) => i)
              .take(10);
      final out =
          await keepAlive<int>(source, every: _tick, beat: (_) => -1).toList();
      expect(out, [for (var i = 0; i < 10; i++) i]);
    });

    test('the beat knows how long it has been quiet, and errors pass through',
        () async {
      final seen = <Duration>[];
      final c = StreamController<int>();
      final sub = keepAlive<int>(c.stream, every: _tick, beat: (q) {
        seen.add(q);
        return -1;
      }).listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(seen.length, greaterThanOrEqualTo(2));
      expect(seen.last, greaterThan(seen.first)); // quiet time keeps growing
      await sub.cancel();
      await c.close();
    });
  });

  group('a turn that goes quiet', () {
    AiSessionRunner runner(AiGenerate g) => AiSessionRunner(
          settings: _settings,
          workspaceRoot: '.',
          generate: g,
          heartbeat: _tick,
        );

    test(
        'sends status beats while waiting for the model, before the first token',
        () async {
      final events = await runner(_slow(const Duration(milliseconds: 250)))
          .ask('x')
          .toList();
      final beats = events.where((e) => e.type == 'status').toList();
      expect(beats, isNotEmpty);
      expect(beats.every((e) => e.data['phase'] == 'waiting_model'), isTrue,
          reason: '${beats.map((e) => e.data)}');
      expect(beats.last.data['idle_seconds'], isA<int>());
      // the beats come first, then the answer and done
      expect(events.indexWhere((e) => e.type == 'status'),
          lessThan(events.indexWhere((e) => e.type == 'text_delta')));
      expect(events.last.type, 'done');
    });

    test('a quick answer has no beats at all', () async {
      final events = await runner(_slow(Duration.zero)).ask('x').toList();
      expect(events.where((e) => e.type == 'status'), isEmpty);
    });

    test('Stop works while the provider is completely silent', () async {
      final r = runner(_slow(Duration.zero, never: true));
      final started = Stopwatch()..start();
      final done = r.ask('x').toList();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      r.cancel();
      final events = await done.timeout(const Duration(seconds: 2));
      expect(events.last.type, 'done');
      expect(started.elapsed, lessThan(const Duration(seconds: 2)));
      expect(events.where((e) => e.type == 'file_proposal'), isEmpty);
    });

    test('after a cancel the next question works normally', () async {
      final r = AiSessionRunner(
        settings: _settings,
        workspaceRoot: '.',
        heartbeat: _tick,
        generate: (
                {required prompt,
                required provider,
                required model,
                apiKey,
                baseUrl,
                onUsage}) =>
            prompt.contains('segunda')
                ? Stream.value('resposta\n')
                : Completer<String>().future.asStream(),
      );
      final first = r.ask('primeira').toList();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      r.cancel();
      await first.timeout(const Duration(seconds: 2));
      final second = await r.ask('segunda').toList();
      expect(
          second
              .where((e) => e.type == 'text_delta')
              .map((e) => e.data['text'])
              .join(),
          'resposta\n');
    });
  });

  test('status and mode_changed are encoded like the other events', () {
    expect(AiEvent.status(phase: 'waiting_model', idleSeconds: 12).toJson(),
        {'type': 'status', 'phase': 'waiting_model', 'idle_seconds': 12});
    expect(AiEvent.modeChanged('plan').toJson(),
        {'type': 'mode_changed', 'mode': 'plan'});
  });
}
