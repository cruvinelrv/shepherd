import 'dart:io';
import 'package:shepherd/src/tools/data/datasources/local/ai_vector_database.dart';
import 'package:shepherd/src/tools/data/models/ai_vector_chunk_model.dart';
import 'package:shepherd/src/tools/domain/services/ai_embedding_service.dart';
import 'package:shepherd/src/tools/domain/services/ai_rag_service.dart';
import 'package:shepherd/src/tools/domain/services/ai_workspace_scanner_service.dart';
import 'package:test/test.dart';

void main() {
  group('AI Local Vector Store & RAG Tests', () {
    late Directory tempDir;
    late AiVectorDatabase vectorDb;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('shepherd_rag_test_');
      vectorDb = AiVectorDatabase(tempDir.path);
    });

    tearDown(() async {
      await vectorDb.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('AiVectorChunkModel serialization to/from Map', () {
      const chunk = AiVectorChunkModel(
        id: 'chunk_1',
        projectName: 'shepherd_core',
        filePath: 'lib/core.dart',
        chunkIndex: 0,
        content: 'void main() { print("hello"); }',
        embedding: [0.1, 0.2, 0.3],
        lastModified: 1700000000,
        tokenCount: 8,
      );

      final map = chunk.toMap();
      final restored = AiVectorChunkModel.fromMap(map);

      expect(restored.id, equals('chunk_1'));
      expect(restored.projectName, equals('shepherd_core'));
      expect(restored.filePath, equals('lib/core.dart'));
      expect(restored.chunkIndex, equals(0));
      expect(restored.content, contains('print("hello")'));
      expect(restored.embedding, equals([0.1, 0.2, 0.3]));
      expect(restored.lastModified, equals(1700000000));
      expect(restored.tokenCount, equals(8));
    });

    test('AiVectorDatabase CRUD and cosine similarity search', () async {
      expect(vectorDb.exists, isFalse);

      final chunk1 = AiVectorChunkModel(
        id: '1',
        projectName: 'projA',
        filePath: 'lib/auth.dart',
        chunkIndex: 0,
        content: 'class AuthService { void login() {} }',
        embedding: [1.0, 0.0, 0.0],
        lastModified: 100,
        tokenCount: 10,
      );

      final chunk2 = AiVectorChunkModel(
        id: '2',
        projectName: 'projA',
        filePath: 'lib/cart.dart',
        chunkIndex: 0,
        content: 'class CartService { void addItem() {} }',
        embedding: [0.0, 1.0, 0.0],
        lastModified: 100,
        tokenCount: 10,
      );

      await vectorDb.upsertChunks([chunk1, chunk2]);
      expect(vectorDb.exists, isTrue);

      final stats = await vectorDb.getStats();
      expect(stats.totalChunks, equals(2));
      expect(stats.totalFiles, equals(2));
      expect(stats.totalProjects, equals(1));

      // Busca similar ao vetor do auth [1.0, 0.0, 0.0]
      final results = await vectorDb.searchSimilar(
        queryEmbedding: [0.9, 0.1, 0.0],
        topK: 2,
        minScore: 0.5,
      );

      expect(results, isNotEmpty);
      expect(results.first.chunk.filePath, equals('lib/auth.dart'));
      expect(results.first.score, greaterThan(0.8));

      // Teste de exclusão por arquivo
      await vectorDb.deleteChunksForFile('projA', 'lib/cart.dart');
      final updatedStats = await vectorDb.getStats();
      expect(updatedStats.totalChunks, equals(1));
      expect(updatedStats.totalFiles, equals(1));
    });

    test('AiWorkspaceScannerService file chunking with overlap', () {
      final scanner = AiWorkspaceScannerService();
      final longContent = StringBuffer();
      for (var i = 1; i <= 60; i++) {
        longContent.writeln('line $i: return doSomethingCriticalWithCodeFunction($i);');
      }

      final chunks = scanner.chunkFile(
        longContent.toString(),
        'lib/service.dart',
        maxChunkChars: 400,
        overlapChars: 80,
      );

      expect(chunks.length, greaterThan(1));
      expect(chunks.first.content, contains('File: lib/service.dart'));
      expect(chunks[1].content, contains('File: lib/service.dart (part 2)'));
    });

    test('AiEmbeddingService produces normalized dense vector offline', () {
      final vec1 = AiEmbeddingService.computeLocalDenseVector('auth login user token');
      final vec2 = AiEmbeddingService.computeLocalDenseVector('auth login user token');
      final vecDifferent = AiEmbeddingService.computeLocalDenseVector('database sql select query');

      expect(vec1.length, equals(128));
      expect(vec1, equals(vec2)); // Determinístico

      // Checa norma unitária (~1.0)
      var sumSq = 0.0;
      for (final v in vec1) {
        sumSq += v * v;
      }
      expect(sumSq, closeTo(1.0, 0.01));

      // Similaridade consigo mesmo deve ser 1.0
      double dot = 0.0;
      for (var i = 0; i < 128; i++) {
        dot += vec1[i] * vec1[i];
      }
      expect(dot, closeTo(1.0, 0.01));

      // Similaridade com texto diferente deve ser menor
      double diffDot = 0.0;
      for (var i = 0; i < 128; i++) {
        diffDot += vec1[i] * vecDifferent[i];
      }
      expect(diffDot, lessThan(0.8));
    });

    test('AiRagService end-to-end indexing and retrieval', () async {
      // Cria arquivos simulados no diretório temporário
      final srcDir = Directory('${tempDir.path}/lib')..createSync(recursive: true);
      File('${srcDir.path}/payment.dart').writeAsStringSync('''
class PaymentProcessor {
  Future<void> chargeCreditCard(String token, double amount) async {
    // Processamento de cartão de crédito
  }
}
''');
      File('${srcDir.path}/user.dart').writeAsStringSync('''
class UserModel {
  final String id;
  final String name;
  UserModel(this.id, this.name);
}
''');

      final ragService = AiRagService(basePath: tempDir.path);
      expect(ragService.isIndexed, isFalse);

      final result = await ragService.indexWorkspace();
      expect(result.indexedFiles, equals(2));
      expect(result.totalChunks, greaterThanOrEqualTo(2));
      expect(ragService.isIndexed, isTrue);

      // Busca semântica por "cartão de crédito e pagamento"
      final matches = await ragService.retrieveRelevantChunks(
        query: 'como processar cartão de crédito e cobrança?',
        topK: 2,
        minScore: 0.1,
      );

      expect(matches, isNotEmpty);
      expect(matches.first.chunk.filePath, contains('payment.dart'));

      final formattedContext = ragService.formatRagContext(matches);
      expect(formattedContext, contains('PaymentProcessor'));
      expect(formattedContext, contains('payment.dart'));
    });
  });
}
