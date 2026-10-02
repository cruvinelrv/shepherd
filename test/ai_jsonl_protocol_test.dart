import 'dart:convert';
import 'package:shepherd/src/tools/domain/services/ai_jsonl_protocol.dart';
import 'package:shepherd/src/tools/domain/services/ai_stream_splitter.dart';
import 'package:test/test.dart';

String text(List<AiSplit> s) => s.whereType<AiSplitText>().map((e) => e.text).join();

void main() {
  group('AiEvent / AiRequest', () {
    test('events encode as one JSON object with a type', () {
      final line = AiEvent.fileProposal(
              id: 'p1', path: 'a/b.txt', content: 'x\ny', isNew: true)
          .encode();
      expect(line.contains('\n'), isFalse);
      final j = jsonDecode(line) as Map;
      expect(j['type'], 'file_proposal');
      expect(j['content'], 'x\ny');
      expect(j['is_new'], true);
    });

    test('requests parse, and bad lines are ignored', () {
      final r = AiRequest.tryParse('{"type":"confirm","id":"p1","approved":true}')!;
      expect(r.type, 'confirm');
      expect(r.str('id'), 'p1');
      expect(r.flag('approved'), true);
      expect(AiRequest.tryParse('not json'), isNull);
      expect(AiRequest.tryParse('{"no":"type"}'), isNull);
      expect(AiRequest.tryParse('   '), isNull);
    });
  });

  group('AiStreamSplitter', () {
    List<AiSplit> run(List<String> chunks) {
      final s = AiStreamSplitter();
      return [for (final c in chunks) ...s.feed(c), ...s.flush()];
    }

    test('removes FILE blocks from prose and announces the path', () {
      final out = run([
        'Vou criar o site.\n```html\n// FILE: meu-site/index.html\n<h1>oi</h1>\n```\nPronto!\n'
      ]);
      expect(out.whereType<AiSplitFileStarted>().single.path, 'meu-site/index.html');
      expect(text(out), 'Vou criar o site.\nPronto!\n');
    });

    test('works when chunks split lines and fences arbitrarily', () {
      final full =
          'A\n```dart\n// FILE: lib/a.dart\nvoid main() {}\n```\nB\n';
      for (var cut = 1; cut < full.length; cut += 3) {
        final out = run([full.substring(0, cut), full.substring(cut)]);
        expect(text(out), 'A\nB\n', reason: 'cut at $cut');
        expect(out.whereType<AiSplitFileStarted>().length, 1);
      }
    });

    test('ordinary code fences stay in the text', () {
      final out = run(['Exemplo:\n```js\nconsole.log(1)\n```\nfim\n']);
      expect(text(out), 'Exemplo:\n```js\nconsole.log(1)\n```\nfim\n');
      expect(out.whereType<AiSplitFileStarted>(), isEmpty);
    });

    test('an unterminated answer is flushed, not lost', () {
      expect(text(run(['sem quebra no fim'])), 'sem quebra no fim');
      expect(text(run(['texto\n```\n'])), 'texto\n```\n');
    });
  });
}
