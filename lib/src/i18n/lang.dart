import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// The languages the CLI speaks. English is the default; Brazilian Portuguese and
/// Spanish are chosen with `shepherd lang`, with `SHEPHERD_LANG`, or taken from the
/// computer's language.
enum ShepherdLang { en, pt, es }

extension ShepherdLangInfo on ShepherdLang {
  /// How the language is named in its own words.
  String get nativeName => switch (this) {
        ShepherdLang.en => 'English',
        ShepherdLang.pt => 'Português (Brasil)',
        ShepherdLang.es => 'Español',
      };
}

/// Reads `en`, `pt`, `pt-BR`, `pt_BR.UTF-8`, `es-MX`, `português`… ; null when it
/// is not a language the CLI has (`C`, `POSIX`, `fr`, empty).
ShepherdLang? parseLang(String? raw) {
  if (raw == null) return null;
  final s = raw.trim().toLowerCase().replaceAll('_', '-');
  if (s.isEmpty) return null;
  const names = {
    'english': ShepherdLang.en,
    'inglês': ShepherdLang.en,
    'ingles': ShepherdLang.en,
    'portuguese': ShepherdLang.pt,
    'português': ShepherdLang.pt,
    'portugues': ShepherdLang.pt,
    'spanish': ShepherdLang.es,
    'español': ShepherdLang.es,
    'espanol': ShepherdLang.es,
  };
  if (names.containsKey(s)) return names[s];
  switch (s.split(RegExp(r'[-.@:]')).first) {
    case 'en':
      return ShepherdLang.en;
    case 'pt':
      return ShepherdLang.pt;
    case 'es':
      return ShepherdLang.es;
  }
  return null;
}

/// Which language to use, and the saved choice.
class LangSettings {
  LangSettings._();

  static Directory _home(Directory? home) =>
      home ??
      Directory(Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '.');

  /// `~/.shepherd/settings.yaml`, where `shepherd lang` saves the choice.
  static File file({Directory? home}) =>
      File(p.join(_home(home).path, '.shepherd', 'settings.yaml'));

  /// The language saved with `shepherd lang`, if any.
  static ShepherdLang? saved({Directory? home}) {
    final f = file(home: home);
    if (!f.existsSync()) return null;
    try {
      final doc = loadYaml(f.readAsStringSync());
      return doc is YamlMap ? parseLang(doc['language']?.toString()) : null;
    } catch (_) {
      return null;
    }
  }

  /// Saves the choice, keeping whatever else the file has.
  static void save(ShepherdLang lang, {Directory? home}) {
    final f = file(home: home);
    final current = <String, dynamic>{};
    if (f.existsSync()) {
      try {
        final doc = loadYaml(f.readAsStringSync());
        if (doc is YamlMap) current.addAll(Map<String, dynamic>.from(doc));
      } catch (_) {}
    }
    current['language'] = lang.name;
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(YamlWriter().write(current));
  }

  /// The language to speak, in this order: `SHEPHERD_LANG`, the saved choice, the
  /// language of the computer (`LC_ALL`, `LC_MESSAGES`, `LANG`, the system locale),
  /// and English when none of those is a language the CLI has.
  static ShepherdLang resolve(
      {Map<String, String>? env, Directory? home, String? localeName}) {
    final e = env ?? Platform.environment;
    final explicit = parseLang(e['SHEPHERD_LANG']);
    if (explicit != null) return explicit;
    final saved = LangSettings.saved(home: home);
    if (saved != null) return saved;
    String? locale = localeName;
    if (locale == null) {
      try {
        locale = Platform.localeName;
      } catch (_) {}
    }
    for (final raw in [e['LC_ALL'], e['LC_MESSAGES'], e['LANG'], locale]) {
      final l = parseLang(raw);
      if (l != null) return l;
    }
    return ShepherdLang.en;
  }
}
