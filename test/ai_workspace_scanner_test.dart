import 'dart:io';

import 'package:path/path.dart' as p;
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
}
