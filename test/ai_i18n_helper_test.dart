import 'package:test/test.dart';
import 'package:shepherd/src/utils/ai_i18n_helper.dart';

void main() {
  group('AiI18nHelper RAG Messages', () {
    test('ragCloudTip returns correct message in PT, EN and ES', () {
      final pt = AiI18nHelper.ragCloudTip(ShepherdLang.pt);
      final en = AiI18nHelper.ragCloudTip(ShepherdLang.en);
      final es = AiI18nHelper.ragCloudTip(ShepherdLang.es);

      expect(pt, contains('--local'));
      expect(pt, contains('--rag'));
      expect(pt, contains('gratuito e ativo por padrão'));

      expect(en, contains('--local'));
      expect(en, contains('--rag'));
      expect(en, contains('free and active by default'));

      expect(es, contains('--local'));
      expect(es, contains('--rag'));
      expect(es, contains('gratuito y activo por defecto'));
    });

    test('ragIndexTip returns correct message in PT, EN and ES', () {
      final pt = AiI18nHelper.ragIndexTip(ShepherdLang.pt);
      final en = AiI18nHelper.ragIndexTip(ShepherdLang.en);
      final es = AiI18nHelper.ragIndexTip(ShepherdLang.es);

      expect(pt, contains("shepherd ai index"));
      expect(en, contains("shepherd ai index"));
      expect(es, contains("shepherd ai index"));
    });

    test('ragStatusLabel formats local vs cloud vs disabled in PT, EN and ES', () {
      // Local ativo
      expect(
        AiI18nHelper.ragStatusLabel(enabled: true, isLocal: true, lang: ShepherdLang.pt),
        equals('Local (Ativo / Gratuito)'),
      );
      expect(
        AiI18nHelper.ragStatusLabel(enabled: true, isLocal: true, lang: ShepherdLang.en),
        equals('Local (Active / Free)'),
      );
      expect(
        AiI18nHelper.ragStatusLabel(enabled: true, isLocal: true, lang: ShepherdLang.es),
        equals('Local (Activo / Gratuito)'),
      );

      // Nuvem ativo via --rag
      expect(
        AiI18nHelper.ragStatusLabel(enabled: true, isLocal: false, lang: ShepherdLang.pt),
        equals('Nuvem (Ativo via --rag)'),
      );
      expect(
        AiI18nHelper.ragStatusLabel(enabled: true, isLocal: false, lang: ShepherdLang.en),
        equals('Cloud (Active via --rag)'),
      );
      expect(
        AiI18nHelper.ragStatusLabel(enabled: true, isLocal: false, lang: ShepherdLang.es),
        equals('Nube (Activo vía --rag)'),
      );

      // Desativado
      expect(
        AiI18nHelper.ragStatusLabel(enabled: false, isLocal: false, lang: ShepherdLang.pt),
        equals('Desativado (use --rag)'),
      );
      expect(
        AiI18nHelper.ragStatusLabel(enabled: false, isLocal: false, lang: ShepherdLang.en),
        equals('Disabled (use --rag)'),
      );
      expect(
        AiI18nHelper.ragStatusLabel(enabled: false, isLocal: false, lang: ShepherdLang.es),
        equals('Desactivado (use --rag)'),
      );
    });
  });
}
