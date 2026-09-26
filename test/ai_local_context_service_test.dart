import 'dart:io';
import 'package:test/test.dart';
import 'package:shepherd/src/tools/domain/services/ai_local_context_service.dart';

void main() {
  group('AiLocalContextService', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('shepherd_context_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('resolves explicit files passed in list', () {
      final sampleFile = File('${tempDir.path}/sample.txt');
      sampleFile.writeAsStringSync('Hello, Shepherd World!');

      final result = AiLocalContextService.resolveLocalFiles(
        prompt: 'Qual o conteudo?',
        explicitFiles: ['sample.txt'],
        basePath: tempDir.path,
      );

      expect(result.resolvedFiles, contains('sample.txt'));
      expect(result.missingFiles, isEmpty);
      expect(result.enrichedPrompt, contains('Hello, Shepherd World!'));
      expect(result.enrichedPrompt, contains('Qual o conteudo?'));
    });

    test('extracts and resolves @file mentions from prompt string', () {
      final file1 = File('${tempDir.path}/pubspec.yaml');
      file1.writeAsStringSync('name: test_app\nversion: 1.0.0');

      final result = AiLocalContextService.resolveLocalFiles(
        prompt: 'Analise o @pubspec.yaml e aponte sugestoes',
        basePath: tempDir.path,
      );

      expect(result.resolvedFiles, contains('pubspec.yaml'));
      expect(result.missingFiles, isEmpty);
      expect(result.enrichedPrompt, contains('name: test_app'));
    });

    test('reports missing files without throwing errors', () {
      final result = AiLocalContextService.resolveLocalFiles(
        prompt: 'Leia @arquivo_inexistente.dart por favor',
        basePath: tempDir.path,
      );

      expect(result.missingFiles, contains('arquivo_inexistente.dart'));
      expect(result.resolvedFiles, isEmpty);
    });
  });
}
