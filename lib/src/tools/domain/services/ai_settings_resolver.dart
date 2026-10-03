import 'dart:io';
import '../../data/models/ai_config_model.dart';
import 'ollama_url_helper.dart';
import 'workspace_manifest_service.dart';

/// Provider/model/credentials the CLI will use for a request, after applying
/// explicit flags, the chosen profile and `ai_config.yaml`.
class AiResolvedSettings {
  final String provider;
  final String model;
  final String? apiKey;
  final String? baseUrl;
  final bool isLocal;

  const AiResolvedSettings({
    required this.provider,
    required this.model,
    this.apiKey,
    this.baseUrl,
    required this.isLocal,
  });

  /// Local providers need no key; cloud ones need a key or a custom base URL.
  bool get hasDirectAccess =>
      isLocal ||
      (apiKey?.isNotEmpty ?? false) ||
      (baseUrl?.isNotEmpty ?? false);
}

/// Explicit [provider]/[model] win; otherwise the [targetProfile] slot (or the
/// active one) from [aiConfig]; otherwise built-in defaults.
AiResolvedSettings resolveAiSettings({
  String? provider,
  String? model,
  String? targetProfile,
  AiConfigModel? aiConfig,
  required bool Function(String? baseUrl, String provider) isLocalProvider,
}) {
  var resolvedProvider = provider;
  var resolvedModel = model;

  if (resolvedProvider != null) {
    resolvedProvider =
        normalizeAiProvider(resolvedProvider) ?? resolvedProvider;
  }
  if (resolvedProvider == null && resolvedModel != null) {
    resolvedProvider = inferAiProviderFromModel(resolvedModel);
  }

  if (resolvedProvider == null && resolvedModel == null && aiConfig != null) {
    final slot = aiConfig.resolveProfileSlot(targetProfile);
    resolvedProvider = slot.provider;
    resolvedModel = slot.model;
  } else if (targetProfile != null && aiConfig != null) {
    final slot = aiConfig.resolveProfileSlot(targetProfile);
    resolvedProvider ??= slot.provider;
    resolvedModel ??= slot.model;
  }

  resolvedProvider ??= aiConfig?.activeProvider ?? 'gemini';
  final providerConfig = aiConfig?.providers[resolvedProvider.toLowerCase()];
  resolvedModel ??= aiConfig?.activeModel ??
      providerConfig?.defaultModel ??
      defaultAiModelFor(resolvedProvider);

  final baseUrl = providerConfig?.baseUrl;
  return AiResolvedSettings(
    provider: resolvedProvider,
    model: resolvedModel,
    apiKey: providerConfig?.apiKey ?? resolveAiEnvApiKey(resolvedProvider),
    baseUrl: baseUrl,
    isLocal: isLocalProvider(baseUrl, resolvedProvider),
  );
}

/// Ollama, LM Studio & co, or any base URL on this machine / LAN.
bool isLocalAiProvider(String? baseUrl, String provider) {
  final p = provider.toLowerCase();
  return p == 'ollama' ||
      p == 'local_ai' ||
      p == 'lan_ai' ||
      (baseUrl != null &&
          baseUrl.isNotEmpty &&
          LanAiHelper.isLocalOrLan(baseUrl));
}

/// Keeps only the manifest projects named in [selected] (matched by id, name,
/// folder path or folder name).
WorkspaceManifest filterManifestProjects(
  WorkspaceManifest manifest,
  List<String> selected,
) {
  String norm(String v) =>
      v.trim().replaceAll('\\', '/').replaceAll(RegExp(r'^\./|/+$'), '');
  final wanted = selected.map(norm).toSet();
  bool matches(WorkspaceProject p) {
    final path = norm(p.path);
    return wanted.contains(path) ||
        wanted.contains(path.split('/').last) ||
        wanted.contains(norm(p.id)) ||
        wanted.contains(norm(p.name));
  }

  return WorkspaceManifest(
    name: manifest.name,
    version: manifest.version,
    projects: manifest.projects.where(matches).toList(),
    rootDir: manifest.rootDir,
  );
}

String? normalizeAiProvider(String input) {
  final clean = input.trim().toLowerCase();
  if (clean == 'openai' ||
      clean == 'chatgpt' ||
      clean == 'chat_gpt' ||
      clean == 'chat-gpt' ||
      clean == 'gpt') {
    return 'openai';
  }
  if (clean == 'anthropic' || clean == 'claude') {
    return 'anthropic';
  }
  if (clean == 'gemini' || clean == 'google') {
    return 'gemini';
  }
  if (clean == 'opencode' || clean == 'opencode.ai' || clean == 'zen') {
    return 'opencode';
  }
  if (clean == 'ollama' || clean == 'local' || clean == 'lan') {
    return 'ollama';
  }
  if (clean == 'local_ai' || clean == 'localai') {
    return 'local_ai';
  }
  return null;
}

String? inferAiProviderFromModel(String model) {
  final m = model.toLowerCase().trim();
  final norm = normalizeAiProvider(m);
  if (norm != null) return norm;

  if (m.startsWith('gpt-') ||
      m.startsWith('gpt4') ||
      m.startsWith('gpt3') ||
      m.startsWith('o1') ||
      m.startsWith('o3') ||
      m.startsWith('text-embedding')) {
    return 'openai';
  }
  if (m.startsWith('claude') || m.startsWith('sonnet')) {
    return 'anthropic';
  }
  if (m.startsWith('gemini-')) {
    return 'gemini';
  }
  if (m.startsWith('opencode/') || m.startsWith('zen/')) {
    return 'opencode';
  }
  if (m.startsWith('llama') ||
      m.startsWith('mistral') ||
      m.startsWith('deepseek') ||
      m.startsWith('qwen') ||
      m.startsWith('phi') ||
      m.startsWith('codellama') ||
      m.startsWith('nomic') ||
      m.startsWith('gemma')) {
    return 'ollama';
  }
  return null;
}

String defaultAiModelFor(String provider) {
  switch (provider.toLowerCase()) {
    case 'gemini':
    case 'google':
      return 'gemini-2.5-flash';
    case 'openai':
    case 'chatgpt':
    case 'chat_gpt':
    case 'chat-gpt':
    case 'gpt':
      return 'gpt-4o';
    case 'anthropic':
    case 'claude':
    case 'sonnet':
      return 'claude-sonnet-5';
    case 'opencode':
    case 'opencode.ai':
    case 'zen':
      return 'qwen3.8-max';
    case 'ollama':
    case 'local':
    case 'lan':
      return 'llama3.1';
    case 'local_ai':
    case 'localai':
    case 'lan_ai':
      return 'local-model';
    default:
      return 'default';
  }
}

String? resolveAiEnvApiKey(String provider) {
  switch (provider.toLowerCase()) {
    case 'gemini':
      return Platform.environment['GEMINI_API_KEY'];
    case 'openai':
      return Platform.environment['OPENAI_API_KEY'];
    case 'anthropic':
      return Platform.environment['ANTHROPIC_API_KEY'];
    case 'opencode':
    case 'zen':
      return Platform.environment['OPENCODE_API_KEY'];
    default:
      return null;
  }
}

String readAiWorkspaceContext({
  required bool includeWorkspace,
  List<String> projects = const [],
}) {
  const paths = [
    '.shepherd/project.yaml',
    '.shepherd/specs.yaml',
    '.shepherd/skills.yaml',
    '.shepherd/environments.yaml',
    '.shepherd/domains.yaml',
    '.shepherd/mcp.json',
    'devops/domains.yaml',
  ];

  final buffer = StringBuffer();

  if (includeWorkspace) {
    var workspace = WorkspaceManifest.tryLoad();
    if (workspace != null && projects.isNotEmpty) {
      workspace = filterManifestProjects(workspace, projects);
    }
    if (workspace != null && workspace.projects.isNotEmpty) {
      buffer.writeln('# .shepherd/workspace.yaml');
      buffer.writeln(workspace.toSummary());
      buffer.writeln();
    }
  }

  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync().trim();
    if (content.isEmpty || isUntouchedScaffold(content)) continue;
    buffer.writeln('# $path');
    buffer.writeln(content);
    buffer.writeln();
  }
  return buffer.toString().trim();
}

/// True for a `.shepherd/*.yaml` that still holds only what `shepherd init`
/// wrote: comments, empty lists, and the template's `specs:` block with its
/// default `architecture: "DDD"`. Nobody chose those values, and passing them
/// on lets the model present a default as a decision ("the project uses DDD").
bool isUntouchedScaffold(String content) {
  final lines = [
    for (final raw in content.split('\n'))
      if (raw.trim().isNotEmpty && !raw.trim().startsWith('#')) raw.trim(),
  ];
  if (lines.isEmpty) return true;
  // Only empty collections: `skills: []`, `domains: []`, `environments: []`.
  final emptyCollection = RegExp(r'^[\w-]+:\s*(\[\]|\{\})$');
  if (lines.every(emptyCollection.hasMatch)) return true;
  // The specs template, exactly as the scaffold writes it.
  final specsTemplate = <RegExp>[
    RegExp(r'^specs:$'),
    RegExp(r'^project:\s*".*"$'),
    RegExp(r'^version:\s*"1\.0\.0"$'),
    RegExp(r'^architecture:\s*"DDD"$'),
    RegExp(r'^requirements:\s*\[\]$'),
  ];
  return lines.length == specsTemplate.length &&
      [
        for (var i = 0; i < lines.length; i++)
          specsTemplate[i].hasMatch(lines[i]),
      ].every((ok) => ok);
}
