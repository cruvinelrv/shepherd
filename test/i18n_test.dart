import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shepherd/src/i18n/catalog.dart';
import 'package:shepherd/src/i18n/i18n.dart';
import 'package:shepherd/src/tools/presentation/commands/lang_command.dart';
import 'package:test/test.dart';

Set<String> _placeholders(String s) =>
    RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m.group(1)!).toSet();

void main() {
  tearDown(I18n.reset);

  group('catalogs', () {
    final en = catalogs[ShepherdLang.en]!;

    test('Portuguese and Spanish have exactly the keys English has', () {
      for (final lang in [ShepherdLang.pt, ShepherdLang.es]) {
        final c = catalogs[lang]!;
        expect(c.keys.toSet().difference(en.keys.toSet()), isEmpty,
            reason: '$lang has keys English lacks');
        expect(en.keys.toSet().difference(c.keys.toSet()), isEmpty, reason: '$lang misses keys');
      }
    });

    test('no empty text, and the same {placeholders} in every language', () {
      for (final key in en.keys) {
        for (final lang in ShepherdLang.values) {
          final v = catalogs[lang]![key]!;
          expect(v.trim(), isNotEmpty, reason: '$lang $key is empty');
          expect(_placeholders(v), _placeholders(en[key]!),
              reason: '$lang $key has different placeholders');
        }
      }
    });

    test('every t(\'key\') used in lib exists', () {
      final used = <String>{};
      final call = RegExp(r"""\bt\(\s*'([a-z_]+\.[a-z_0-9]+)'""");
      for (final f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        used.addAll(call.allMatches(f.readAsStringSync()).map((m) => m.group(1)!));
      }
      expect(used, isNotEmpty);
      expect(used.difference(en.keys.toSet()), isEmpty);
    });

    test('no hardcoded accented Portuguese/Spanish outside the catalogs', () {
      final accent = RegExp(r'[áâãàéêíóôõúçÁÉÍÓÚÇñ¿¡]');
      final offenders = <String>[];
      for (final f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final path = p.relative(f.path);
        if (path.contains('i18n/') || path.endsWith('ai_i18n_helper.dart')) {
          continue;
        }
        var n = 0;
        for (final line in f.readAsLinesSync()) {
          n++;
          final code = line.trimLeft();
          if (code.startsWith('//') || code.startsWith('*')) continue;
          if (accent.hasMatch(line)) offenders.add('$path:$n');
        }
      }
      expect(offenders, isEmpty, reason: 'move the text to the catalog and use t()');
    });
  });

  group('t()', () {
    test('fills {placeholders} and follows the chosen language', () {
      I18n.use(ShepherdLang.en);
      expect(t('update.up_to_date', {'version': '1.2.3'}), contains('latest'));
      I18n.use(ShepherdLang.pt);
      expect(t('update.up_to_date', {'version': '1.2.3'}),
          allOf(contains('mais recente'), contains('1.2.3')));
      I18n.use(ShepherdLang.es);
      expect(t('update.up_to_date', {'version': '1.2.3'}), contains('última versión'));
    });

    test('an unknown key shows the key itself', () {
      expect(t('nope.nothing'), 'nope.nothing');
    });
  });

  group('language resolution', () {
    late Directory home;
    setUp(() => home = Directory.systemTemp.createTempSync('lang_'));
    tearDown(() => home.deleteSync(recursive: true));

    test('defaults to English when nothing says otherwise', () {
      expect(LangSettings.resolve(env: {}, home: home, localeName: 'fr_FR'), ShepherdLang.en);
      expect(LangSettings.resolve(env: {'LANG': 'C'}, home: home, localeName: ''), ShepherdLang.en);
    });

    test('follows the computer language when it is Portuguese or Spanish', () {
      expect(LangSettings.resolve(env: {'LANG': 'pt_BR.UTF-8'}, home: home, localeName: 'en_US'),
          ShepherdLang.pt);
      expect(LangSettings.resolve(env: {}, home: home, localeName: 'es_MX'), ShepherdLang.es);
    });

    test('order: SHEPHERD_LANG, then the saved choice, then the computer', () {
      LangSettings.save(ShepherdLang.es, home: home);
      expect(LangSettings.resolve(env: {'LANG': 'pt_BR'}, home: home), ShepherdLang.es);
      expect(LangSettings.resolve(env: {'SHEPHERD_LANG': 'en', 'LANG': 'pt_BR'}, home: home),
          ShepherdLang.en);
    });

    test('saving keeps the other settings in the file', () {
      final f = LangSettings.file(home: home);
      f.parent.createSync(recursive: true);
      f.writeAsStringSync('other: 1\n');
      LangSettings.save(ShepherdLang.pt, home: home);
      final text = f.readAsStringSync();
      expect(text, allOf(contains('other'), contains('pt')));
    });

    test('parseLang understands the usual spellings', () {
      expect(parseLang('pt-BR'), ShepherdLang.pt);
      expect(parseLang('pt_BR.UTF-8'), ShepherdLang.pt);
      expect(parseLang('Português'), ShepherdLang.pt);
      expect(parseLang('es-AR'), ShepherdLang.es);
      expect(parseLang('EN'), ShepherdLang.en);
      expect(parseLang('fr'), isNull);
      expect(parseLang(''), isNull);
      expect(parseLang(null), isNull);
    });
  });

  group('shepherd lang', () {
    late Directory home;
    setUp(() => home = Directory.systemTemp.createTempSync('lang_'));
    tearDown(() => home.deleteSync(recursive: true));

    test('without arguments it shows the language and the options', () {
      final out = <String>[];
      final code = runLangCommand([], out: out.add, home: home, env: {});
      expect(code, 0);
      expect(out.join('\n'), allOf(contains('en'), contains('pt'), contains('es')));
    });

    test('with a language it saves it and speaks it', () {
      final out = <String>[];
      expect(runLangCommand(['pt'], out: out.add, home: home, env: {}), 0);
      expect(LangSettings.saved(home: home), ShepherdLang.pt);
      expect(out.join(), contains('Português'));
    });

    test('an unknown language is refused and nothing is saved', () {
      final out = <String>[];
      I18n.use(ShepherdLang.en);
      expect(runLangCommand(['fr'], out: out.add, home: home, env: {}), 1);
      expect(LangSettings.saved(home: home), isNull);
    });

    test('warns when SHEPHERD_LANG overrides the saved choice', () {
      final out = <String>[];
      runLangCommand(['es'], out: out.add, home: home, env: {'SHEPHERD_LANG': 'en'});
      expect(out.join('\n'), contains('SHEPHERD_LANG'));
    });
  });
}
