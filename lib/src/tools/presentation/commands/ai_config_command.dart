import 'dart:io';
import '../../domain/services/ai_config_service.dart';

/// Interactive `shepherd ai config` — sets the model and API key used by
/// `shepherd ai`. Only Gemini is supported today; `provider` is still
/// stored so adding a second one later doesn't need a config-format
/// migration for people who already ran this.
Future<void> runAiConfigCommand() async {
  final service = AiConfigService();
  final current = service.load();

  print('\nShepherd AI — Configuração');
  if (current != null) {
    print('Configuração atual:');
    print('  provider: ${current.provider}');
    print('  model:    ${current.model}');
    print('  apiKey:   ${_maskApiKey(current.apiKey)}');
    print('');
  }

  const provider = 'gemini'; // único suportado por enquanto
  print('Provider: $provider (único suportado por enquanto)');

  final defaultModel = current?.model ?? 'gemini-2.5-flash';
  stdout.write('Model [$defaultModel]: ');
  final modelInput = stdin.readLineSync()?.trim();
  final model = (modelInput == null || modelInput.isEmpty) ? defaultModel : modelInput;

  stdout.write(current != null
      ? 'API Key (Enter para manter a atual): '
      : 'API Key: ');
  // stdin.echoMode throws when stdin isn't a real terminal (e.g. piped
  // input from a script) — fall back to visible input rather than crashing.
  bool echoDisabled = false;
  try {
    stdin.echoMode = false;
    echoDisabled = true;
  } catch (_) {
    // no terminal to toggle echo on — input will just be visible.
  }
  final apiKeyInput = stdin.readLineSync()?.trim();
  if (echoDisabled) {
    try {
      stdin.echoMode = true;
    } catch (_) {}
  }
  print('');

  final apiKey =
      (apiKeyInput == null || apiKeyInput.isEmpty) ? current?.apiKey : apiKeyInput;

  if (apiKey == null || apiKey.isEmpty) {
    print('❌ API Key é obrigatória.');
    exitCode = 1;
    return;
  }

  service.save(AiConfig(provider: provider, model: model, apiKey: apiKey));
  print('✅ Configuração salva em .shepherd/ai_config.yaml (adicionado ao .shepherd/.gitignore)');
}

String _maskApiKey(String apiKey) {
  if (apiKey.length <= 4) return '****';
  return '${'*' * (apiKey.length - 4)}${apiKey.substring(apiKey.length - 4)}';
}
