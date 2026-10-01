import 'dart:io';

enum ShepherdLang { en, pt, es }

class AiI18nHelper {
  /// Detects default language from environment variables or operating system locale.
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

  /// Returns system language code ('en', 'pt', 'es').
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

  /// Returns friendly tip when RAG is bypassed on cloud providers to save tokens.
  static String ragCloudTip([ShepherdLang? lang]) {
    final l = lang ?? detectSystemLanguage();
    switch (l) {
      case ShepherdLang.pt:
        return "💡 Dica: O RAG com modelos locais (--local) é gratuito e ativo por padrão. Para incluir o contexto do RAG com este modelo em nuvem, use '--rag'.";
      case ShepherdLang.es:
        return "💡 Consejo: El RAG con modelos locales (--local) es gratuito y activo por defecto. Para incluir el contexto del RAG con este modelo en la nube, use '--rag'.";
      case ShepherdLang.en:
        return "💡 Tip: RAG with local models (--local) is free and active by default. To include RAG context with this cloud model, use '--rag'.";
    }
  }

  /// Returns tip about creating the vector index when not found.
  static String ragIndexTip([ShepherdLang? lang]) {
    final l = lang ?? detectSystemLanguage();
    switch (l) {
      case ShepherdLang.pt:
        return "💡 Dica: Execute 'shepherd ai index' para criar um índice vetorial local do seu workspace.";
      case ShepherdLang.es:
        return "💡 Consejo: Ejecuta 'shepherd ai index' para crear un índice vectorial local de tu workspace.";
      case ShepherdLang.en:
        return "💡 Tip: Run 'shepherd ai index' to create a local vector index of your workspace.";
    }
  }

  /// Returns formatted label for RAG status display.
  static String ragStatusLabel({required bool enabled, required bool isLocal, ShepherdLang? lang}) {
    final l = lang ?? detectSystemLanguage();
    if (!enabled) {
      switch (l) {
        case ShepherdLang.pt:
          return 'Desativado (use --rag)';
        case ShepherdLang.es:
          return 'Desactivado (use --rag)';
        case ShepherdLang.en:
          return 'Disabled (use --rag)';
      }
    }
    if (isLocal) {
      switch (l) {
        case ShepherdLang.pt:
          return 'Local (Ativo / Gratuito)';
        case ShepherdLang.es:
          return 'Local (Activo / Gratuito)';
        case ShepherdLang.en:
          return 'Local (Active / Free)';
      }
    }
    switch (l) {
      case ShepherdLang.pt:
        return 'Nuvem (Ativo via --rag)';
      case ShepherdLang.es:
        return 'Nube (Activo vía --rag)';
      case ShepherdLang.en:
        return 'Cloud (Active via --rag)';
    }
  }
}

