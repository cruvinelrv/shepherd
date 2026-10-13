import 'dart:io';

import '../../../../utils/ansi_colors.dart';
import '../../../domain/services/ai_config_service.dart';
import '../../../domain/services/ai_model_catalog_service.dart';
import '../ai_cloud_model_picker.dart';
import 'model_options.dart';
import 'model_prompts.dart';
import 'model_selection.dart';

/// What [chooseModel] came to: a model, a cancellation (the user pressed Enter)
/// or neither (what was typed matched nothing).
typedef ModelChoice = ({ModelSwitchOption? selected, bool cancelled});

/// Asks which model to use. With [arg] empty it shows the menu; otherwise [arg]
/// is a provider name (opens its list) or a model name. Nothing is saved here.
Future<ModelChoice> chooseModel({
  required AiConfigModel? aiConfig,
  String arg = '',
  String? activeProvider,
  String? activeModel,
}) async {
  final options = await buildModelSwitchOptions(aiConfig);
  final provider = activeProvider ?? aiConfig?.activeProvider ?? 'gemini';
  final model = activeModel ??
      aiConfig?.activeModel ??
      AiModelCatalogService.defaultGeminiModel;

  var input = arg.trim();
  if (input.isEmpty) {
    _printMenu(options, provider, model);
    stdout.write(
        'Escolha uma opção [1-${options.length}] ou digite o nome do modelo (ou Enter para cancelar): ');
    input = stdin.readLineSync()?.trim() ?? '';
    if (input.isEmpty) return (selected: null, cancelled: true);
  }

  final lower = input.toLowerCase();
  ModelSwitchOption? selected;
  if (lower == '1' || lower == 'ollama' || lower == 'local') {
    selected = await promptOllamaModelSelection(
        aiConfig: aiConfig, currentModel: model);
  } else if (lower == '5' ||
      lower == 'opencode' ||
      lower == 'opencode.ai' ||
      lower == 'zen') {
    selected = await promptOpenCodeModelSelection(
        aiConfig: aiConfig, currentModel: model);
  } else if (cloudProviderForChoice(input) != null) {
    selected = await promptCloudProviderSelection(
      providerId: cloudProviderForChoice(input)!,
      aiConfig: aiConfig,
      options: options,
      activeProvider: provider,
      activeModel: model,
    );
  } else {
    selected = selectModelOption(input, options, aiConfig);
  }
  return (selected: selected, cancelled: false);
}

void _printMenu(List<ModelSwitchOption> options, String currentProvider,
    String currentModel) {
  const line =
      '────────────────────────────────────────────────────────────────────────';
  print(
      '\n${AnsiColors.bold}🤖 Shepherd AI — Trocar de Modelo / Provedor${AnsiColors.reset}');
  print(line);
  print(
      'Modelo Atual: ${AnsiColors.brightCyan}$currentModel${AnsiColors.reset} (${providerDisplayName(currentProvider)})\n');
  print('Opções disponíveis:');
  for (var i = 0; i < options.length; i++) {
    final opt = options[i];
    final isCurrent =
        opt.provider == currentProvider && opt.model == currentModel;
    final check = isCurrent
        ? ' ${AnsiColors.brightGreen}★ (Ativo)${AnsiColors.reset}'
        : '';
    print('  [${i + 1}] ${opt.label}$check');
  }
  print(line);
}

/// Makes [selected] the default model (provider, model, key and address) in
/// `ai_config.yaml`.
void saveModelChoice(AiConfigModel? aiConfig, ModelSwitchOption selected) {
  if (aiConfig == null) return;
  final providers =
      Map<String, AiProviderConfigEntity>.from(aiConfig.providers);
  final existing = providers[selected.provider];
  final known = List<String>.from(existing?.knownModels ?? []);
  if (!known.contains(selected.model)) known.add(selected.model);
  providers[selected.provider] = AiProviderConfigModel(
    id: selected.provider,
    apiKey: selected.apiKey ?? existing?.apiKey,
    baseUrl: selected.baseUrl ?? existing?.baseUrl,
    defaultModel: selected.model,
    knownModels: known,
  );
  AiConfigService().save(aiConfig.copyWith(
    activeProvider: selected.provider,
    activeModel: selected.model,
    providers: providers,
  ));
}

/// `shepherd ai model [name]`: choose and save the default model.
Future<void> handleModelSwitchCommand(List<String> args) async {
  final aiConfig = AiConfigService().load();
  final choice = await chooseModel(aiConfig: aiConfig, arg: args.join(' '));
  if (choice.cancelled) {
    print('ℹ️  Operação cancelada.\n');
    return;
  }
  final selected = choice.selected;
  if (selected == null) {
    print(
        '❌ Opção ou modelo não reconhecido. Digite "shepherd ai model" para ver a lista.\n');
    return;
  }
  saveModelChoice(aiConfig, selected);
  print(
      '\n${AnsiColors.brightGreen}✅ Modelo padrão atualizado para: ${selected.model} (${providerDisplayName(selected.provider)})${AnsiColors.reset}\n');
}
