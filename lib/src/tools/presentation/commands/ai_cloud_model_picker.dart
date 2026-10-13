import 'dart:io';

import '../../domain/services/ai_model_catalog_service.dart';
import '../../../utils/ansi_colors.dart';

/// Cloud providers whose model is picked from a list in `/model`.
const _cloudChoices = <String, String>{
  '2': 'openai',
  'openai': 'openai',
  'chatgpt': 'openai',
  'chat_gpt': 'openai',
  'chat-gpt': 'openai',
  'gpt': 'openai',
  '3': 'anthropic',
  'anthropic': 'anthropic',
  'claude': 'anthropic',
  '4': 'gemini',
  'gemini': 'gemini',
  'google': 'gemini',
};

/// The provider id when [input] names a whole cloud provider (an option
/// number or a provider name), as opposed to a specific model.
String? cloudProviderForChoice(String input) =>
    _cloudChoices[input.trim().toLowerCase()];

// Gemini lists models that cannot chat (speech, image, live audio).
final _notForChat = RegExp(r'tts|image|imagen|veo|live|audio|embedding|aqa');

/// Orders names so that "gemini-3.10" comes after "gemini-3.8": digit runs
/// are compared as numbers, everything else as text.
int _naturalCompare(String a, String b) {
  final ta = RegExp(r'\d+|\D+').allMatches(a).map((m) => m[0]!).toList();
  final tb = RegExp(r'\d+|\D+').allMatches(b).map((m) => m[0]!).toList();
  for (var i = 0; i < ta.length && i < tb.length; i++) {
    final na = int.tryParse(ta[i]), nb = int.tryParse(tb[i]);
    final c =
        (na != null && nb != null) ? na.compareTo(nb) : ta[i].compareTo(tb[i]);
    if (c != 0) return c;
  }
  return ta.length.compareTo(tb.length);
}

/// The models to offer: what the provider reports right now first (newest
/// names on top), then the ones saved for this provider and the built-in
/// catalog. [current] is always present.
List<String> buildCloudModelList({
  required String providerId,
  required List<String> online,
  required List<String> saved,
  required String current,
}) {
  bool usable(String m) => providerId != 'gemini' || !_notForChat.hasMatch(m);
  final fresh = online.where(usable).toList()
    ..sort((a, b) => _naturalCompare(b, a));
  return {
    ...fresh,
    ...saved,
    ...?AiModelCatalogService.defaultModels[providerId],
    current,
  }.toList();
}

/// Lists the models of a cloud provider and lets the user pick by number.
/// Enter keeps [currentModel]; `m` asks for a name by hand. The list comes
/// from the provider's API with the user's key, so new models show up
/// without a Shepherd release.
Future<String> promptCloudModelSelection({
  required String providerId,
  required String providerLabel,
  required String? apiKey,
  required String currentModel,
  required List<String> savedModels,
  Future<List<String>> Function()? fetchOnline,
  String? Function()? readLine,
}) async {
  final read = readLine ?? stdin.readLineSync;
  var online = <String>[];
  if (apiKey != null && apiKey.isNotEmpty) {
    stdout.write('🔍 Buscando modelos em $providerLabel... ');
    try {
      online = await (fetchOnline ??
              () => AiModelCatalogService()
                  .fetchOnlineModels(providerId: providerId, apiKey: apiKey))()
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
    stdout.writeln(online.isEmpty
        ? '${AnsiColors.gray}usando a lista padrão.${AnsiColors.reset}\n'
        : '${AnsiColors.brightGreen}${online.length} modelo(s).${AnsiColors.reset}\n');
  } else {
    print(
        'ℹ️  Sem chave de API para $providerLabel (use `shepherd ai config`); '
        'mostrando a lista padrão.\n');
  }

  final models = buildCloudModelList(
    providerId: providerId,
    online: online,
    saved: savedModels,
    current: currentModel,
  );

  print('${AnsiColors.bold}Modelos de $providerLabel:${AnsiColors.reset}');
  for (var i = 0; i < models.length; i++) {
    final star = models[i] == currentModel
        ? ' ${AnsiColors.brightGreen}★ (Ativo)${AnsiColors.reset}'
        : '';
    print('  [${i + 1}] ${models[i]}$star');
  }
  print('  [m] ✍️ Digitar o nome de outro modelo');
  print(
      '────────────────────────────────────────────────────────────────────────');
  stdout.write(
      'Escolha [1-${models.length}] ou [m] (Enter para manter "$currentModel"): ');
  final input = read()?.trim() ?? '';
  if (input.isEmpty) return currentModel;

  if (input.toLowerCase() == 'm') {
    stdout.write('Nome do modelo: ');
    final typed = read()?.trim() ?? '';
    return typed.isEmpty ? currentModel : typed;
  }
  final idx = int.tryParse(input);
  if (idx != null) {
    if (idx >= 1 && idx <= models.length) return models[idx - 1];
    print('ℹ️  Opção $idx não existe; mantido: $currentModel.');
    return currentModel;
  }
  return input;
}
