// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> enAi2 = {
  'installer.downloading': 'Downloading the AI engine {version}...',
  'installer.feed_status': 'The updates server answered {status}.',
  'installer.bad_signature':
      'The signature of the engine\'s version list does not match. Nothing was installed.',
  'installer.bad_feed': 'Invalid version list: {detail}',
  'installer.download_status': 'Could not download the engine ({status}).',
  'installer.bad_hash':
      'The downloaded file does not match the hash of the signed list. Nothing was installed.',
  'installer.server_status': 'The server answered {status}.',
  'installer.retrying': 'Unstable connection, trying again ({i}/{max})...',
  'installer.no_binary': 'The engine package does not contain {exe}.',
  'rpc.engine_exited': 'The AI engine stopped unexpectedly.',
  'help.projects':
      'Limit the context (and the files the AI may change) to these projects, folders at the workspace root. Empty = the whole workspace.',
  'help.model': 'AI model (e.g. gemini-3.8-flash, gpt-4o, llama3.1).',
  'help.provider': 'AI provider: gemini, openai, anthropic or ollama.',
  'help.mode':
      'fast (asks before writing), plan (only plans) or auto (writes right away).',
  'help.plan': 'Shortcut for --mode plan.',
  'help.auto': 'Shortcut for --mode auto.',
  'help.rag': 'Turn the workspace context on or off (on by default).',
  'help.file': 'Attach the content of local files to the question.',
  'help.profile': 'Model profile: advanced, medium or local.',
  'help.local': 'Use the local model profile.',
  'help.engine_path': 'Show where the AI engine is (installing it if missing).',
  'help.update_engine': 'Look for a new version of the AI engine now.',
  'help.config_sync': 'Sync the online model catalog.',
  'launcher.usage':
      'Usage: shepherd ai ["your question"] [-m model] [-p provider] [--plan|--auto] [--projects a,b] [-f file]\n     shepherd ai config [--sync]\n     shepherd ai model [model_name]\n     shepherd ai --engine-path | --update-engine',
  'launcher.bad_args': '❌ Error: {e}\n{usage}',
  'launcher.login_required': '❌ Sign in to use Shepherd AI: `shepherd login`.',
  'launcher.file_not_found': '⚠️  File not found: {path}',
  'opt.name_local': 'Local (Ollama)',
  'opt.local':
      'Pick an Ollama model [RAG on / zero cost] (Current: {model}{lan})',
  'opt.openai': '{model} [Economical / Cloud]',
  'opt.anthropic': '{model} [Reasoning / Cloud]',
  'opt.gemini': '{model} [Fast / Cloud]',
  'opt.opencode':
      'Pick a model [qwen, deepseek, claude, gpt...] (Current: {model})',
  'opt.name_lan': 'Local server (LAN)',
  'opt.lan': '{model} [RAG on / LAN] ({url})',
  'dn.gemini': 'Google Gemini (Direct)',
  'dn.openai': 'OpenAI (Direct)',
  'dn.anthropic': 'Anthropic Claude (Direct)',
  'dn.opencode': 'OpenCode Zen (opencode.ai)',
  'dn.ollama': 'Ollama (Local / LAN)',
  'dn.lan': 'Local / LAN server',
  'models.menu_prompt':
      'Pick an option [1-{n}] or type the model name (or Enter to cancel): ',
  'models.title': '🤖 Shepherd AI — Switch model / provider',
  'models.current': 'Current model: {model} ({provider})\n',
  'models.options': 'Available options:',
  'models.active': '★ (Active)',
  'models.cancelled': 'ℹ️  Operation cancelled.\n',
  'models.unknown':
      '❌ Option or model not recognized. Type "shepherd ai model" to see the list.\n',
  'models.default_set': '✅ Default model updated to: {model} ({provider})\n',
  'picker.fetching': '🔍 Looking for models at {provider}... ',
  'picker.default_list': 'using the default list.',
  'picker.n_models': '{n} model(s).',
  'picker.no_key':
      'ℹ️  No API key for {provider} (use `shepherd ai config`); showing the default list.\n',
  'picker.title': 'Models from {provider}:',
  'picker.type_name': '  [m] ✍️ Type the name of another model',
  'picker.choose': 'Pick [1-{n}] or [m] (Enter to keep "{model}"): ',
  'picker.model_name': 'Model name: ',
  'picker.no_option': 'ℹ️  Option {n} does not exist; kept: {model}.',
  'notice.usage':
      'ℹ️  Usage report: Shepherd AI sends your company\'s Shepherd account usage numbers (provider, model, tokens and duration) so it can follow how the AI is used. Questions, answers, file names and code are never sent. To turn it off, use `telemetry: false` in .shepherd/ai_config.yaml. This notice appears once.',
  'diff.new_file': '(new file)',
  'diff.modification': '(modification)',
  'diff.more_lines': '  ... {n} more lines',
  'diff.too_big':
      '  (file too big to compare line by line: {old} → {new} lines)',
  'diff.no_changes': '  (no differences)',
  'diff.continues': '  ... (the difference continues)',
  'ollama.fetching':
      '\n🔍 Looking for the models available in Ollama ({url})... ',
  'ollama.detected': '{n} model(s) detected!',
  'ollama.offline': 'Ollama is offline or unreachable at {url}.',
  'ollama.lan_tip':
      '💡 Is it on another machine on the network? Type {key} to set the IP/port.\n',
  'ollama.models_title': 'Models available in your Ollama:',
  'ollama.change_url':
      '  [u] 🌐 Change the Ollama IP / URL on the network (current: {url})',
  'ollama.choose':
      'Pick a model [1-{n}], [u] for IP/URL (Enter to keep "{model}"): ',
  'ollama.ask_url':
      '\nType the IP or hostname of Ollama on the network (e.g. http://192.168.1.50:11434) [{url}]: ',
  'ollama.url_updated': '✅ Ollama address updated to: {url}',
  'opencode.setup_title': 'Setting up OpenCode Zen (opencode.ai)',
  'opencode.intro':
      'OpenCode Zen gives access to many top models with a single API key.',
  'opencode.get_key':
      'Get your key at: https://opencode.ai or https://opencode.ai/zen\n',
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
};
