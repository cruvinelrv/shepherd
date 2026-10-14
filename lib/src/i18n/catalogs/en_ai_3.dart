// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> enAi3 = {
  'opencode.ask_key': 'Type your OpenCode API key (or Enter to cancel): ',
  'opencode.cancelled': 'ℹ️  Setup cancelled.\n',
  'opencode.key_saved':
      '✅ OpenCode API key saved in .shepherd/ai_config.yaml!\n',
  'opencode.fetching':
      '🔍 Looking for the model catalog at OpenCode Zen ({url})... ',
  'opencode.n_models': '{n} model(s) available!\n',
  'opencode.default_catalog': 'Using the default OpenCode Zen catalog.\n',
  'opencode.models_title': 'Models available at OpenCode Zen:',
  'opencode.update_key': '  [k] 🔑 Update the OpenCode API key',
  'opencode.type_model': '  [m] ✍️ Type another model name by hand',
  'opencode.choose':
      'Pick an option [1-{n}], [k] key, [m] other (Enter to keep "{model}"): ',
  'opencode.new_key': '\nType the new OpenCode API key: ',
  'opencode.key_updated': '✅ API key updated successfully!\n',
  'opencode.ask_model':
      '\nType the model ID at OpenCode (e.g. deepseek-v4-pro, qwen3.8-max): ',
  'render.phase_indexing': 'indexing the workspace',
  'render.phase_searching': 'looking for context',
  'render.phase_writing': 'writing',
  'render.phase_thinking': 'thinking',
  'render.phase_waiting': 'waiting for the model',
  'render.trimmed':
      '✂️  {n} older message(s) left out of the context to fit the model\'s window.',
  'render.preparing': '📄 preparing {path}...',
  'render.written': '✅ {path} written',
  'render.write_failed': '❌ could not write {path}',
  'render.blocked': '🚫 {path} was not proposed: {reason}',
  'render.indexed': '🧠 {project}: {n} file(s) in the index',
  'render.context_ready': '🧠 Context ready ({backend})',
  'render.pruned': ' · {n} old index(es) removed',
  'render.context_chunks':
      '📎 {n} snippet(s) from the workspace in the context',
  'render.rag_unavailable': '⚠️  Workspace context unavailable: {message}',
  'err.session_expired':
      'Your session expired. Run `shepherd login` and try again.',
  'err.login_required': 'Sign in to use Shepherd AI: `shepherd login`.',
  'err.not_configured':
      'No AI provider configured. Run `shepherd ai config`. ({detail})',
  'err.ollama_offline':
      'The Ollama server did not respond. Open Ollama (or set its address with `shepherd ai config`).',
  'err.invalid_key':
      'The provider rejected the API key. Update it with `shepherd ai config`.',
  'err.model_unavailable':
      'The model {model} is not available for your account. Pick another with /model (or `shepherd ai model`).',
  'err.rate_limited':
      'The provider\'s usage limit was reached. Wait a moment and try again.',
  'err.busy': 'The engine is still answering the previous question.',
};
