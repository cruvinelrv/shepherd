import '../i18n/i18n.dart';

export '../i18n/lang.dart' show ShepherdLang;

class AiI18nHelper {
  /// The language in use: SHEPHERD_LANG, then `shepherd lang`, then the system
  /// locale, then English.
  static ShepherdLang detectSystemLanguage() => I18n.current;

  /// Returns the language code in use ('en', 'pt', 'es').
  static String get systemLocale => detectSystemLanguage().name;

  /// Returns multilingual label for a model profile.
  static String profileLabel(String profile, [ShepherdLang? lang]) {
    final l = lang ?? detectSystemLanguage();
    final p = profile.toLowerCase();

    if (p == 'advanced' || p == 'avancado' || p == 'avanzado' || p == 'deep') {
      switch (l) {
        case ShepherdLang.pt:
          return 'Avançado';
        case ShepherdLang.es:
          return 'Avanzado';
        case ShepherdLang.en:
          return 'Advanced';
      }
    }

    if (p == 'medium' || p == 'medio' || p == 'fast') {
      switch (l) {
        case ShepherdLang.pt:
          return 'Médio';
        case ShepherdLang.es:
          return 'Medio';
        case ShepherdLang.en:
          return 'Medium';
      }
    }

    // 'local' is identical across EN, PT and ES
    return 'Local';
  }

  /// Returns profile purpose description.
  static String profilePurpose(String profile, [ShepherdLang? lang]) {
    final l = lang ?? detectSystemLanguage();
    final p = profile.toLowerCase();

    if (p == 'advanced' || p == 'avancado' || p == 'avanzado' || p == 'deep') {
      switch (l) {
        case ShepherdLang.pt:
          return 'Tarefas complexas, arquitetura e raciocínio profundo';
        case ShepherdLang.es:
          return 'Tareas complejas, arquitectura y razonamiento profundo';
        case ShepherdLang.en:
          return 'Complex tasks, architecture and deep reasoning';
      }
    }

    if (p == 'medium' || p == 'medio' || p == 'fast') {
      switch (l) {
        case ShepherdLang.pt:
          return 'Respostas ágeis para o dia a dia e comandos rápidos';
        case ShepherdLang.es:
          return 'Respuestas ágiles para el día a día y comandos rápidos';
        case ShepherdLang.en:
          return 'Agile day-to-day responses and fast commands';
      }
    }

    switch (l) {
      case ShepherdLang.pt:
        return '100% privado, offline e gratuito (Ollama, LM Studio, etc.)';
      case ShepherdLang.es:
        return '100% privado, offline y gratuito (Ollama, LM Studio, etc.)';
      case ShepherdLang.en:
        return '100% private, offline and zero cost (Ollama, LM Studio, etc.)';
    }
  }
}
