import 'dart:io';

class LanAiHelper {
  /// Verifica se uma URL ou host pertence à rede local ou máquina privada
  /// (localhost, 127.0.0.1, 0.0.0.0, ::1, IPs de LAN 192.168.x.x, 10.x.x.x, 172.16-31.x.x, *.local).
  static bool isLocalOrLan(String urlOrHost) {
    final clean = urlOrHost.trim();
    if (clean.isEmpty) return false;
    try {
      final uri = Uri.tryParse(clean.startsWith('http') ? clean : 'http://$clean');
      final host = (uri?.host ?? clean).toLowerCase();
      if (host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '0.0.0.0' ||
          host == '::1' ||
          host.endsWith('.local')) {
        return true;
      }
      if (host.startsWith('192.168.') || host.startsWith('10.')) {
        return true;
      }
      final match = RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.').hasMatch(host);
      if (match) return true;
    } catch (_) {}
    return false;
  }

  /// Normaliza URLs de servidores de IA locais ou em qualquer máquina na rede local
  /// (LM Studio, vLLM, LocalAI, Jan, Ollama, etc.), corrigindo schemes e barras finais.
  static String normalize(String? input, {String defaultUrl = 'http://localhost:11434'}) {
    String url = input?.trim() ?? '';
    if (url.isEmpty) {
      url = defaultUrl;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return url;
  }

  /// Constrói a URL para o endpoint de chat/completions (OpenAI-compatível)
  /// suportando servidores locais (LM Studio, vLLM, LocalAI, Jan, llama.cpp, etc.).
  static String buildChatCompletionsUrl(String baseUrl) {
    var clean = normalize(baseUrl, defaultUrl: 'http://localhost:1234/v1');
    if (clean.endsWith('/chat/completions')) {
      return clean;
    }
    if (clean.endsWith('/v1')) {
      return '$clean/chat/completions';
    }
    return '$clean/v1/chat/completions';
  }

  /// Constrói a URL para o endpoint de listagem de modelos (OpenAI-compatível)
  /// suportando servidores locais e na rede local.
  static String buildModelsUrl(String baseUrl) {
    var clean = normalize(baseUrl, defaultUrl: 'http://localhost:1234/v1');
    if (clean.endsWith('/models')) {
      return clean;
    }
    if (clean.endsWith('/v1')) {
      return '$clean/models';
    }
    return '$clean/v1/models';
  }
}

/// Helper para retrocompatibilidade com Ollama
class OllamaUrlHelper {
  static String normalize(String? input) {
    final envFallback = Platform.environment['OLLAMA_HOST'] ??
        Platform.environment['OLLAMA_BASE_URL'] ??
        'http://localhost:11434';
    return LanAiHelper.normalize(input, defaultUrl: envFallback);
  }

  static bool isLocalOrLan(String url) => LanAiHelper.isLocalOrLan(url);
}
