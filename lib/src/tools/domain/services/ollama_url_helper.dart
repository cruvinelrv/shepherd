import 'dart:io';

class OllamaUrlHelper {
  /// Normaliza URLs do Ollama permitindo conexões em localhost,
  /// máquinas na rede local (LAN via IP ou hostname, ex: 192.168.1.50:11434 ou ollama.local:11434),
  /// e respeitando variáveis de ambiente OLLAMA_HOST / OLLAMA_BASE_URL.
  static String normalize(String? input) {
    String url = input?.trim() ?? '';
    if (url.isEmpty) {
      url = Platform.environment['OLLAMA_HOST'] ??
          Platform.environment['OLLAMA_BASE_URL'] ??
          'http://localhost:11434';
    }

    // Se o usuário digitou apenas host:porta sem scheme (ex: 192.168.0.10:11434)
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    // Remove barras no final
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return url;
  }
}
