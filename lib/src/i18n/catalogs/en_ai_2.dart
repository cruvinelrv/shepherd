// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> enAi2 = {
  'chat.write_failed': '❌ could not write {path}\n',
  'chat.skipped': '⏭️  {path} skipped\n',
  'chat.mode_set': '✅ Mode {mode}',
  'chat.mode_current': 'Current mode: {mode}. Use /mode fast|plan|auto.',
  'chat.scope_set': '✅ Scope: {scope}',
  'chat.rag_note':
      'The workspace context is set when starting: use --rag or --no-rag in `shepherd ai`.',
  'chat.unknown_command': 'Unknown command. Type /help.',
  'chat.switch_cancelled': 'ℹ️  Switch cancelled. Kept: {model}.',
  'chat.model_unknown':
      '❌ Option or model not recognized. Type "/model" to see the list.',
  'chat.model_changed': '✅ Model changed to: {model} ({provider})',
  'chat.help':
      '  /plan | /auto | /fast       change the mode (text after it is asked right away)\n  /run [auto]                 carry out the plan: files (you confirm) and terminal commands (you confirm each)\n  /model [name]               switch the model or the provider\n  /projects a,b               limit the context and the files to these projects\n  exit                        quit\nCtrl+C during an answer stops only the answer.',
  'chat.hint_full':
      '/plan only plan · /run carry out the plan · /auto write now · /fast ask first · /model · /projects · /help · exit',
  'chat.hint_short':
      '/plan /run /auto /fast · /model · /projects · /help · exit',
  'chat.help_mode_cmd': '/mode [fast|plan|auto]',
  'installer.env_missing': '{env} points to a file that does not exist: {path}',
  'installer.download_failed':
      'Could not download the AI engine ({e}). Connect to the internet and try again.',
  'installer.no_package':
      'There is no AI engine published for this computer yet ({platform}).',
  'installer.unknown_platform': 'unknown platform',
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
};
