import 'dart:io';

class LanAiHelper {
  /// Checks whether a URL or host belongs to the local network or a private machine
  /// (localhost, 127.0.0.1, 0.0.0.0, ::1, LAN IPs 192.168.x.x, 10.x.x.x, 172.16-31.x.x, *.local).
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

  /// Normalizes local or LAN AI server URLs
  /// (LM Studio, vLLM, LocalAI, Jan, Ollama, etc.), sanitizing schemes and trailing slashes.
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

  /// Builds the URL for the chat/completions endpoint (OpenAI-compatible),
  /// supporting local servers (LM Studio, vLLM, LocalAI, Jan, llama.cpp, etc.).
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

  /// Builds the URL for the models listing endpoint (OpenAI-compatible),
  /// supporting local and LAN servers.
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

/// Helper for backwards compatibility with Ollama
class OllamaUrlHelper {
  static String normalize(String? input) {
    final envFallback = Platform.environment['OLLAMA_HOST'] ??
        Platform.environment['OLLAMA_BASE_URL'] ??
        'http://localhost:11434';
    return LanAiHelper.normalize(input, defaultUrl: envFallback);
  }

  static bool isLocalOrLan(String url) => LanAiHelper.isLocalOrLan(url);
}
