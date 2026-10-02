import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shepherd/src/tools/domain/services/ai_knowledge_loader.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('knowledge'));
  tearDown(() => tmp.deleteSync(recursive: true));

  void write(String rel, String content) {
    final f = File(p.join(tmp.path, rel))..createSync(recursive: true);
    f.writeAsStringSync(content);
  }

  test('front matter gives name and description, the rest is the body', () {
    final r = AiKnowledge.parseFrontMatter(
        '---\nname: "Tom de voz"\ndescription: Ao escrever textos\n---\nSeja breve.\n');
    expect(r.meta['name'], 'Tom de voz');
    expect(r.meta['description'], 'Ao escrever textos');
    expect(r.body, 'Seja breve.');
    expect(AiKnowledge.parseFrontMatter('só texto').body, 'só texto');
  });

  test('reads instructions, skills and specs from workspace and project', () {
    write('.shepherd/SHEPHERD.md', 'Responda em português.');
    write('.shepherd/skills/tom/SKILL.md',
        '---\nname: Tom de voz\ndescription: textos\n---\nSeja breve.');
    write('loja/.shepherd/SHEPHERD.md', 'A loja vende bolos.');
    write('loja/.shepherd/specs/cardapio.md', 'Todo bolo tem preço.');
    write('outra/.shepherd/SHEPHERD.md', 'NÃO DEVE APARECER');

    final text = AiKnowledge(tmp.path).read(projects: ['loja']);
    expect(text, contains('Responda em português.'));
    expect(text, contains('Skill "Tom de voz" (workspace)'));
    expect(text, contains('Use quando: textos'));
    expect(text, contains('A loja vende bolos.'));
    expect(text, contains('Especificação "cardapio" (projeto loja)'));
    expect(text, isNot(contains('NÃO DEVE APARECER')));
  });

  test('empty when nothing was written; the size cap is respected', () {
    expect(AiKnowledge(tmp.path).read(), isEmpty);
    write('.shepherd/SHEPHERD.md', 'x' * 500);
    write('a/.shepherd/SHEPHERD.md', 'y' * 500);
    final text = AiKnowledge(tmp.path, maxChars: 600).read(projects: ['a']);
    expect(text, contains('omitidas'));
    expect(text, isNot(contains('y')));
  });
}
