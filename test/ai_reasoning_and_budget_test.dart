import 'package:test/test.dart';
import 'package:shepherd/src/tools/data/models/ai_vector_chunk_model.dart';
import 'package:shepherd/src/tools/domain/services/ai_reasoning_stream_transformer.dart';
import 'package:shepherd/src/tools/domain/services/ai_context_budget_service.dart';

void main() {
  group('AiReasoningStreamTransformer', () {
    test('separa blocos normais e blocos de pensamento <think> no stream', () async {
      final input = Stream.fromIterable([
        'Olá! ',
        '<think>Preciso ',
        'calcular a ',
        'resposta.',
        '</think>Aqui ',
        'está o resultado.',
      ]);

      final transformer = const AiReasoningStreamTransformer();
      final chunks = await input.transform(transformer).toList();

      final normalText = chunks.where((c) => !c.isReasoning).map((c) => c.text).join();
      final reasoningText = chunks.where((c) => c.isReasoning).map((c) => c.text).join();

      expect(normalText, equals('Olá! Aqui está o resultado.'));
      expect(reasoningText, equals('Preciso calcular a resposta.'));
    });

    test('trata tags <think> divididas entre múltiplos chunks do stream', () async {
      final input = Stream.fromIterable([
        'Início: ',
        '<thi',
        'nk>pensamento interno</thi',
        'nk> fim.',
      ]);

      final transformer = const AiReasoningStreamTransformer();
      final chunks = await input.transform(transformer).toList();

      final normalText = chunks.where((c) => !c.isReasoning).map((c) => c.text).join();
      final reasoningText = chunks.where((c) => c.isReasoning).map((c) => c.text).join();

      expect(normalText, equals('Início:  fim.'));
      expect(reasoningText, equals('pensamento interno'));
    });

    test('stripThinking remove blocos <think> e <thought> do texto final', () {
      const raw = 'Antes <think>pensando aqui...</think> Meio <thought>mais raciocinio</thought> Depois';
      expect(AiReasoningStreamTransformer.stripThinking(raw), equals('Antes  Meio  Depois'));
    });
  });

  group('AiContextBudgetService', () {
    test('compacta blocos de código grandes em turnos antigos para nuvem', () {
      final history = [
        {'role': 'user', 'content': 'Crie um model'},
        {
          'role': 'assistant',
          'content': 'Aqui está:\n```dart\nline 1\nline 2\nline 3\nline 4\nline 5\nline 6\nline 7\nline 8\n```\nO que achou?',
        },
        {'role': 'user', 'content': 'Gostei, agora adicione testes'},
        {
          'role': 'assistant',
          'content': 'Última resposta com código:\n```dart\ntest 1\ntest 2\n```',
        },
      ];

      final compacted = AiContextBudgetService.compactHistory(history, isLocal: false);

      // Resposta anterior foi colapsada para economizar tokens
      expect(compacted[1]['content'], contains('lines of code collapsed to save context tokens'));

      // Última resposta permanece intacta
      expect(compacted[3]['content'], contains('test 1\ntest 2'));
    });

    test('formatBudgetedRagContext respeita teto de caracteres para nuvem', () {
      final matches = [
        AiRagMatchModel(
          chunk: const AiVectorChunkModel(
            id: 'c1',
            projectName: 'shepherd',
            filePath: 'lib/file1.dart',
            chunkIndex: 0,
            content: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n'
                'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB\n'
                'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n'
                'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD\n'
                'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n'
                'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n'
                'GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG\n'
                'HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH\n'
                'IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n'
                'JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ\n'
                'KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK\n'
                'LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL\n'
                'MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\n'
                'NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN\n'
                'OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\n'
                'PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP\n'
                'QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ\n'
                'RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR\n'
                'SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS\n'
                'TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT\n'
                'UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU\n'
                'VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV\n'
                'WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n'
                'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n'
                'YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY\n'
                'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ\n',
            embedding: [],
            lastModified: 1000,
            tokenCount: 750,
          ),
          score: 0.95,
        ),
        AiRagMatchModel(
          chunk: const AiVectorChunkModel(
            id: 'c2',
            projectName: 'shepherd',
            filePath: 'lib/file2.dart',
            chunkIndex: 0,
            content: 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB\n',
            embedding: [],
            lastModified: 1000,
            tokenCount: 750,
          ),
          score: 0.85,
        ),
      ];

      final budgeted = AiContextBudgetService.formatBudgetedRagContext(
        matches,
        isLocal: false, // nuvem
      );

      // Limite para nuvem é ~2400 caracteres
      expect(budgeted.length, lessThanOrEqualTo(2600));
      expect(budgeted, contains('lib/file1.dart'));
      expect(budgeted, contains('Remaining snippet truncated to save context tokens'));
    });
  });
}
