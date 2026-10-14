// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> ptAi1 = {
  'cmd.proposed': '▶ A IA quer executar, em',
  'cmd.risky':
      '  ⚠️  Este comando pode apagar dados ou mudar o sistema. Leia antes de aceitar.',
  'cmd.ask': 'Executar? [s/N]: ',
  'cmd.ask_risky': 'Este é arriscado. Executar mesmo assim? [s/N]: ',
  'cmd.auto_run': '  (modo auto: executando sem perguntar)',
  'cmd.skipped': '  Ignorado.',
  'cmd.no_folder': '  A pasta não existe: {path}',
  'cmd.ok': '✅ Concluído.',
  'cmd.failed': '❌ Falhou (código de saída {code}).',
  'cmd.timed_out': '❌ Demorou demais e foi interrompido.',
  'cmd.not_run':
      '{n} comando(s) proposto(s), não executado(s): não há terminal para perguntar.',
  'cmd.sending_results': '↩ Enviando os resultados para a IA...',
  'cmd.running_plan': '▶ Executando o plano (modo {mode}).',
  'cfg.syncing': '🔄 Sincronizando catálogo de modelos online...',
  'cfg.synced': '✅ Catálogo sincronizado com sucesso!',
  'cfg.title': '🤖 Shepherd AI — Configuração Multi-Modelos',
  'cfg.active_line': 'Provedor Ativo: {provider} | Modelo: {model}',
  'cfg.p_opencode': 'OpenCode Zen (opencode.ai - Chave única multi-modelos)',
  'cfg.p_local_ai':
      'Servidor Local / Rede Local (LM Studio, vLLM, Jan, LocalAI)',
  'cfg.not_configured': '[Não configurado]',
  'cfg.configured': '[Configurado: {key}]',
  'cfg.menu_profiles':
      '  [P] 🎯 Perfis de Modelos / Slots (Advanced, Medium, Local)',
  'cfg.menu_sync':
      '  [S] 🔄 Sincronizar catálogo de modelos de todos os provedores',
  'cfg.menu_save': '  [0] Salvar e Sair',
  'cfg.choose_main': '\nEscolha uma opção [1-{n}, P, S, 0]: ',
  'cfg.saved': '\n✅ Configurações salvas em .shepherd/ai_config.yaml\n',
  'cfg.models_synced': '✅ Modelos sincronizados e salvos!',
  'cfg.invalid': 'Opção inválida.',
  'cfg.setup': '\n⚙️  Configurando {name}',
  'cfg.opencode_url': 'URL do OpenCode Zen [{url}]: ',
  'cfg.key_keep': 'API Key (Enter para manter {key}): ',
  'cfg.key_opencode':
      'API Key do OpenCode Zen (obtenha em https://opencode.ai/zen): ',
  'cfg.where_runs': '\nOnde está rodando o motor {name}?',
  'cfg.where_here': '  [1] No meu próprio computador (localhost)',
  'cfg.where_lan': '  [2] Em outro computador na rede local (LAN / IP)',
  'cfg.where_choose': 'Escolha [1 ou 2, Enter para manter {url}]: ',
  'cfg.set_localhost': 'Endereço configurado como localhost: {url}',
  'cfg.ask_host':
      'Digite o IP ou hostname da outra máquina (ex: http://192.168.1.50:{port}) [{url}]: ',
  'cfg.key_local_keep':
      'API Key (Enter para manter {key} ou deixe em branco se não requer): ',
  'cfg.key_local_new':
      'API Key (opcional para servidores locais/LAN, pressione Enter para pular): ',
  'cfg.pick_default': '\nSelecione o modelo padrão para {name}:',
  'cfg.selected_badge': '(Selecionado)',
  'cfg.add_manual': '  [+] Adicionar novo modelo manualmente',
  'cfg.fetch_online':
      '  [R] 🔄 Buscar modelos disponíveis online nesta conta/servidor',
  'cfg.finish': '  [C] Concluir seleção de modelo',
  'cfg.choose_model_menu': '\nEscolha uma opção [1-{n}, +, R, C]: ',
  'cfg.ask_model_id':
      '\nDigite o identificador exato do modelo (ex: gemini-3.8-flash): ',
  'cfg.model_added': 'Modelo "{model}" adicionado e selecionado!',
  'cfg.querying': '\nConsultando modelos disponíveis via API...',
  'cfg.found_online': 'Encontrados {n} modelos online!',
  'cfg.none_online': 'Nenhum modelo retornado ou não foi possível conectar.',
  'cfg.model_selected': 'Modelo "{model}" selecionado.',
  'cfg.make_active':
      '\nDeseja definir {name} ({model}) como o provedor ativo do Shepherd? [S/n]: ',
  'cfg.provider_done': '✅ Provedor {name} configurado com sucesso!',
  'prof.title': '\n🎯 Perfis de Modelos',
  'prof.advanced': '  [1] 🧠 Avançado:',
  'prof.medium': '  [2] ⚡ Médio:   ',
  'prof.local': '  [3] 🏡 Local:   ',
  'prof.default_star': '★ (Padrão)',
  'prof.use_advanced':
      'Uso: shepherd ai --advanced "..." ou /advanced no shell',
  'prof.use_medium': 'Uso: shepherd ai --medium "..." ou /medium no shell',
  'prof.use_local':
      'Uso: shepherd ai --local "..." ou /local no shell (custo zero)',
  'prof.set_default': '  [D] Definir perfil ativo padrão (Atual: {profile})',
  'prof.back': '  [0] Voltar ao menu principal',
  'prof.pick_option': '\nEscolha uma opção [1-3, D, 0]: ',
  'prof.pick_default':
      'Escolha o perfil padrão [1: Advanced, 2: Medium, 3: Local]: ',
  'prof.default_changed': '✅ Perfil padrão alterado para: {profile}!',
  'prof.pick_provider': '\nEscolha o provedor para o perfil {slot}:',
  'prof.pick_provider_n': 'Escolha um provedor [1-{n}]: ',
  'prof.pick_model': '\nEscolha o modelo para o perfil {slot} ({provider}):',
  'prof.pick_model_n': 'Escolha um modelo [1-{n}] ou digite o nome: ',
  'prof.slot_done': '✅ Perfil {slot} configurado com: {provider} ({model})!',
  'chat.whole_workspace': 'workspace inteiro',
  'chat.mode_where': 'modo {mode} | {where}',
  'chat.offline_notice':
      '⚠️  Sem conexão com o Shepherd Union: usando a última validação do seu login.',
  'chat.commands_line':
      'Comandos: /plan /auto /fast · /model · /projects a,b · /help · "sair"\n',
  'chat.bye': '\nAté mais!',
  'chat.interrupted': '⏹ interrompido',
  'chat.footer':
      '{model} · {provider} · modo {mode} · {ms} ms · {prompt}+{completion} tokens ({kind})',
  'chat.kind_local': 'Local / Gratuito',
  'chat.kind_cloud': 'Nuvem',
  'chat.unsaved':
      '⚠️  {n} arquivo(s) proposto(s) e não gravado(s): use --auto para gravar sem perguntar.',
  'chat.proposed_change': '📝 Alteração proposta pela IA:',
  'chat.apply_prompt': 'Aplicar em {path}? [S/n]: ',
  'chat.applied': '✅ {path} gravado\n',
  'chat.write_failed': '❌ não foi possível gravar {path}\n',
  'chat.skipped': '⏭️  {path} ignorado\n',
  'chat.mode_set': '✅ Modo {mode}',
  'chat.mode_current': 'Modo atual: {mode}. Use /mode fast|plan|auto.',
  'chat.scope_set': '✅ Escopo: {scope}',
};
