import 'dart:io';

enum ShepherdLang { en, pt, es }

class AiI18nHelper {
  /// Detecta o idioma padrão a partir do ambiente ou do sistema operacional
  static ShepherdLang detectSystemLanguage() {
    try {
      final envLang = Platform.environment['SHEPHERD_LANG']?.toLowerCase() ??
          Platform.environment['LANG']?.toLowerCase() ??
          Platform.localeName.toLowerCase();

      if (envLang.startsWith('pt')) return ShepherdLang.pt;
      if (envLang.startsWith('es')) return ShepherdLang.es;
    } catch (_) {}
    return ShepherdLang.en;
  }

  /// Retorna o código do idioma do sistema ('en', 'pt', 'es')
  static String get systemLocale => detectSystemLanguage().name;

  /// Retorna o rótulo multilíngue para um perfil de modelo
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

    // 'local' é idêntico em EN, PT e ES
    return 'Local';
  }

  /// Retorna a descrição de propósito do perfil
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
