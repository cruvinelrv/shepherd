import 'catalog.dart';
import 'lang.dart';

export 'lang.dart';

/// The language this run speaks. Resolved once, on first use.
class I18n {
  I18n._();

  static ShepherdLang? _current;

  static ShepherdLang get current => _current ??= LangSettings.resolve();

  /// Uses [lang] from now on (the `lang` command, and tests).
  static void use(ShepherdLang lang) => _current = lang;

  /// Forgets the choice: the next use resolves the language again.
  static void reset() => _current = null;
}

/// The text for [key] in the current language, with each `{name}` replaced by
/// [args]. English fills in for a text a language lacks, and the key itself shows
/// when even English has none, so a mistake is visible and never a crash.
String t(String key, [Map<String, Object?> args = const {}]) {
  var text =
      catalogs[I18n.current]?[key] ?? catalogs[ShepherdLang.en]![key] ?? key;
  args.forEach((name, value) => text = text.replaceAll('{$name}', '$value'));
  return text;
}
