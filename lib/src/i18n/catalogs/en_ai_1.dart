// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> enAi1 = {
  'cmd.proposed': '▶ The AI wants to run, in',
  'cmd.risky':
      '  ⚠️  This command can delete data or change the system. Read it before you accept.',
  'cmd.ask': 'Run it? [y/N/e = edit]: ',
  'cmd.ask_risky': 'This one is risky. Run it anyway? [y/N/e = edit]: ',
  'cmd.auto_run': '  (auto mode: running without asking)',
  'cmd.skipped': '  Skipped.',
  'cmd.no_folder': '  The folder does not exist: {path}',
  'cmd.ok': '✅ Done.',
  'cmd.failed': '❌ It failed (exit code {code}).',
  'cmd.timed_out': '❌ It took too long and was stopped.',
  'cmd.not_run':
      '{n} command(s) proposed, not run: there is no terminal to ask you.',
  'cmd.sending_results': '↩ Sending the results to the AI...',
  'cmd.running_plan': '▶ Carrying out the plan (mode {mode}).',
  'cmd.ctrl_c': '  (Ctrl+C stops it and goes back to the chat)',
  'cmd.stopped': '⏹ Stopped by you.',
  'cmd.edit': 'Type the command to run instead (empty = skip): ',
  'cmd.hint_no_device':
      'No device given (-d): Flutter picks any connected one, a physical phone included. For web use `-d chrome`.',
  'cmd.hint_all_platforms':
      'No --platforms given: this creates iOS, Android, web and the rest. For web only use `--platforms=web`.',
  'cfg.syncing': '🔄 Syncing the online model catalog...',
  'cfg.synced': '✅ Catalog synced!',
  'cfg.title': '🤖 Shepherd AI — Multi-Model Setup',
  'cfg.active_line': 'Active provider: {provider} | Model: {model}',
  'cfg.p_opencode': 'OpenCode Zen (opencode.ai - one key, many models)',
  'cfg.p_local_ai': 'Local / LAN server (LM Studio, vLLM, Jan, LocalAI)',
  'cfg.not_configured': '[Not configured]',
  'cfg.configured': '[Configured: {key}]',
  'cfg.menu_profiles':
      '  [P] 🎯 Model profiles / slots (Advanced, Medium, Local)',
  'cfg.menu_sync': '  [S] 🔄 Sync the model catalog of all providers',
  'cfg.menu_save': '  [0] Save and exit',
  'cfg.choose_main': '\nPick an option [1-{n}, P, S, 0]: ',
  'cfg.saved': '\n✅ Settings saved in .shepherd/ai_config.yaml\n',
  'cfg.models_synced': '✅ Models synced and saved!',
  'cfg.invalid': 'Invalid option.',
  'cfg.setup': '\n⚙️  Setting up {name}',
  'cfg.opencode_url': 'OpenCode Zen URL [{url}]: ',
  'cfg.key_keep': 'API Key (Enter to keep {key}): ',
  'cfg.key_opencode':
      'OpenCode Zen API Key (get it at https://opencode.ai/zen): ',
  'cfg.where_runs': '\nWhere is the {name} engine running?',
  'cfg.where_here': '  [1] On my own computer (localhost)',
  'cfg.where_lan': '  [2] On another computer on the local network (LAN / IP)',
  'cfg.where_choose': 'Pick [1 or 2, Enter to keep {url}]: ',
  'cfg.set_localhost': 'Address set to localhost: {url}',
  'cfg.ask_host':
      'Type the IP or hostname of the other machine (e.g. http://192.168.1.50:{port}) [{url}]: ',
  'cfg.key_local_keep':
      'API Key (Enter to keep {key}, or leave blank if it needs none): ',
  'cfg.key_local_new':
      'API Key (optional for local/LAN servers, press Enter to skip): ',
  'cfg.pick_default': '\nPick the default model for {name}:',
  'cfg.selected_badge': '(Selected)',
  'cfg.add_manual': '  [+] Add a new model by hand',
  'cfg.fetch_online':
      '  [R] 🔄 Look for the models available online in this account/server',
  'cfg.finish': '  [C] Finish choosing the model',
  'cfg.choose_model_menu': '\nPick an option [1-{n}, +, R, C]: ',
  'cfg.ask_model_id':
      '\nType the exact model identifier (e.g. gemini-3.8-flash): ',
  'cfg.model_added': 'Model "{model}" added and selected!',
  'cfg.querying': '\nQuerying the available models through the API...',
  'cfg.found_online': 'Found {n} models online!',
  'cfg.none_online': 'No model returned, or it was not possible to connect.',
  'cfg.model_selected': 'Model "{model}" selected.',
  'cfg.make_active':
      '\nSet {name} ({model}) as Shepherd\'s active provider? [Y/n]: ',
  'cfg.provider_done': '✅ Provider {name} configured!',
  'prof.title': '\n🎯 Model Slots',
  'prof.advanced': '  [1] 🧠 Advanced:',
  'prof.medium': '  [2] ⚡ Medium:  ',
  'prof.local': '  [3] 🏡 Local:   ',
  'prof.default_star': '★ (Default)',
  'prof.use_advanced':
      'Use: shepherd ai --advanced "..." or /advanced in the shell',
  'prof.use_medium': 'Use: shepherd ai --medium "..." or /medium in the shell',
  'prof.use_local':
      'Use: shepherd ai --local "..." or /local in the shell (zero cost)',
  'prof.set_default':
      '  [D] Set the default active profile (current: {profile})',
  'prof.back': '  [0] Back to the main menu',
  'prof.pick_option': '\nPick an option [1-3, D, 0]: ',
  'prof.pick_default':
      'Pick the default profile [1: Advanced, 2: Medium, 3: Local]: ',
  'prof.default_changed': '✅ Default profile changed to: {profile}!',
  'prof.pick_provider': '\nPick the provider for the {slot} profile:',
  'prof.pick_provider_n': 'Pick a provider [1-{n}]: ',
  'prof.pick_model': '\nPick the model for the {slot} profile ({provider}):',
  'prof.pick_model_n': 'Pick a model [1-{n}] or type its name: ',
  'prof.slot_done': '✅ Profile {slot} set to: {provider} ({model})!',
  'chat.whole_workspace': 'the whole workspace',
  'chat.mode_where': 'mode {mode} | {where}',
  'chat.offline_notice':
      '⚠️  No connection to Shepherd Union: using the last validation of your login.',
  'chat.commands_line':
      'Commands: /plan /auto /fast · /model · /projects a,b · /help · "exit"\n',
  'chat.bye': '\nSee you!',
  'chat.interrupted': '⏹ interrupted',
  'chat.footer':
      '{model} · {provider} · mode {mode} · {ms} ms · {prompt}+{completion} tokens ({kind})',
  'chat.kind_local': 'Local / Free',
  'chat.kind_cloud': 'Cloud',
  'chat.unsaved':
      '⚠️  {n} proposed file(s) not written: use --auto to write without asking.',
  'chat.proposed_change': '📝 Change proposed by the AI:',
  'chat.apply_prompt': 'Apply to {path}? [Y/n]: ',
  'chat.applied': '✅ {path} written\n',
};
