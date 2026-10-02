import 'package:test/test.dart';
import 'package:shepherd/src/tools/presentation/commands/ai_command.dart';

void main() {
  group('Shepherd AI Modes & Tiers Tests', () {
    test('formatAiSystemPreamble injects working directory and tool access', () {
      final preamble = formatAiSystemPreamble(
        workingDir: '/dev/projetos/meu_app',
        isLocal: true,
      );

      expect(preamble, contains('Shepherd CLI'));
      expect(preamble, contains('/dev/projetos/meu_app'));
      expect(preamble, contains('RAG local'));
      expect(preamble, contains('ferramentas MCP'));
    });

    test('formatAiModePrompt returns PLAN directives for plan mode', () {
      final prompt = formatAiModePrompt('plan');

      expect(prompt, contains('MODO DE PLANEJAMENTO (PLAN MODE)'));
      expect(prompt, contains('Objetivo e Escopo'));
      expect(prompt, contains('Análise de Arquitetura'));
      expect(prompt, contains('Arquivos a Criar ou Modificar'));
      expect(prompt, contains('Não execute alterações de escrita'));
    });

    test('formatAiModePrompt returns AUTO directives for auto mode', () {
      final prompt = formatAiModePrompt('auto');

      expect(prompt, contains('MODO AUTÔNOMO (AUTO MODE)'));
      expect(prompt, contains('// FILE: caminho/do/arquivo.ext'));
      expect(prompt, contains('aplicará as alterações de arquivos diretamente'));
    });

    test('formatAiModePrompt returns empty for fast mode', () {
      final prompt = formatAiModePrompt('fast');
      expect(prompt, isEmpty);
    });

    test('formatAiTierPrompt returns DEEP directives when tier is deep', () {
      final prompt = formatAiTierPrompt('deep');
      expect(prompt, contains('Diretrizes de Raciocínio DEEP'));
      expect(prompt, contains('profundidade técnica'));
    });

    test('formatAiTierPrompt returns empty for fast tier', () {
      final prompt = formatAiTierPrompt('fast');
      expect(prompt, isEmpty);
    });

    test('AI command parser supports mode, plan, auto, and tier flags', () {
      final parser = createAiCommandParser();

      final results = parser.parse(['--plan', '--deep', '--rag']);
      expect(results['plan'], isTrue);
      expect(results['deep'], isTrue);
      expect(results['rag'], isTrue);

      final autoResults = parser.parse(['--auto', '--mode', 'auto', '--tier', 'deep']);
      expect(autoResults['auto'], isTrue);
      expect(autoResults['mode'], equals('auto'));
      expect(autoResults['tier'], equals('deep'));
    });
  });
}
