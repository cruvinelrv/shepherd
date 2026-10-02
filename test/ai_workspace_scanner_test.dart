import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shepherd/src/tools/domain/services/ai_config_service.dart';
import 'package:shepherd/src/tools/domain/services/ai_workspace_scanner_service.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late Directory previous;

  void write(String rel, String content) {
    File(p.join(tmp.path, rel))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  setUp(() {
    previous = Directory.current;
    tmp = Directory(
        Directory.systemTemp.createTempSync('scanner').resolveSymbolicLinksSync());
    Directory.current = tmp; // keeps WorkspaceManifest.tryLoad() inside the temp dir
  });
  tearDown(() {
    Directory.current = previous;
    tmp.deleteSync(recursive: true);
  });

  Set<String> found() => AiWorkspaceScannerService(tmp.path)
      .discoverFiles()
      .map((t) => t.relativePath)
      .toSet();

  test('indexes the plain-text, data and extra-language files people write', () {
    for (final f in [
      'notas.txt', 'precos.csv', 'dados.tsv', 'feed.xml', 'config.toml',
      'app.ini', 'estilo.scss', 'App.vue', 'index.php', 'Main.java', 'util.c',
      'run.ps1', 'README.rst',
    ]) {
      write(f, 'conteudo de $f');
    }
    expect(found(), containsAll(<String>[
      'notas.txt', 'precos.csv', 'dados.tsv', 'feed.xml', 'config.toml',
      'app.ini', 'estilo.scss', 'App.vue', 'index.php', 'Main.java', 'util.c',
      'run.ps1', 'README.rst',
    ]));
  });

  test('still skips secrets, binaries, generated files and hidden folders', () {
    write('ok.txt', 'x');
    write('.env', 'API_KEY=segredo');
    write('foto.png', 'png');
    write('doc.pdf', 'pdf');
    write('desenho.svg', '<svg/>');
    write('debug.log', 'log');
    write('yarn.lock', 'lock');
    write('package-lock.json', '{}');
    write('pnpm-lock.yaml', 'x');
    write('app.min.js', 'x');
    write('.git/config.txt', 'x');
    write('node_modules/lib/readme.txt', 'x');
    expect(found(), {'ok.txt'});
  });

  test('files above the size cap are skipped, smaller ones are kept', () {
    write('pequeno.csv', 'a,b\n1,2\n');
    write('enorme.csv', 'x' * (AiWorkspaceScannerService.maxIndexableBytes + 1));
    expect(found(), {'pequeno.csv'});
  });

  test('a .txt note can now be chunked and indexed like code', () {
    write('receita.txt', 'Bolo de banana. Ingrediente secreto: cardamomo-roxo.');
    final target = AiWorkspaceScannerService(tmp.path).discoverFiles().single;
    final chunks = AiWorkspaceScannerService(tmp.path)
        .chunkFile(target.file.readAsStringSync(), target.relativePath);
    expect(chunks, isNotEmpty);
    expect(chunks.first.content, contains('cardamomo-roxo'));
  });

  group('configurable size limit', () {
    int resolve({int? kb, Map<String, String> env = const {}}) =>
        AiWorkspaceScannerService.resolveMaxBytes(
          config: kb == null
              ? null
              : AiConfigModel(activeProvider: 'x', activeModel: 'y', ragMaxFileKb: kb),
          env: env,
        );

    test('default, config value and env override (env wins)', () {
      expect(resolve(), 256 * 1024);
      expect(resolve(kb: 1024), 1024 * 1024);
      expect(resolve(kb: 1024, env: {'SHEPHERD_RAG_MAX_FILE_KB': '64'}), 64 * 1024);
    });

    test('nonsense values fall back instead of breaking indexing', () {
      expect(resolve(env: {'SHEPHERD_RAG_MAX_FILE_KB': 'abc'}), 256 * 1024);
      expect(resolve(kb: 0), 256 * 1024);
      expect(resolve(kb: -5), 256 * 1024);
      expect(resolve(kb: 999999), 256 * 1024);
      // a bad env value still lets a good config value through
      expect(resolve(kb: 512, env: {'SHEPHERD_RAG_MAX_FILE_KB': '0'}), 512 * 1024);
    });

    test('the limit read from ai_config.yaml is actually applied', () {
      write('.shepherd/ai_config.yaml',
          'active_provider: ollama\nactive_model: m\nrag_max_file_kb: 1\n'
          'providers:\n  ollama:\n    default_model: m\n');
      write('curto.csv', 'a,b\n1,2\n');
      write('medio.csv', 'x' * 2000); // above 1 KB
      expect(found(), {'curto.csv'});
    });

    test('rag_max_file_kb survives a load/save round trip', () {
      final cfg = AiConfigModel.fromYaml({
        'active_provider': 'ollama',
        'active_model': 'm',
        'rag_max_file_kb': 512,
        'providers': {'ollama': {'default_model': 'm'}},
      });
      expect(cfg.ragMaxFileKb, 512);
      expect(cfg.toMap()['rag_max_file_kb'], 512);
      expect(cfg.copyWith(activeModel: 'z').ragMaxFileKb, 512);
    });
  });
}
