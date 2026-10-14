// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> ptAi2 = {
  'chat.mode_current': 'Modo atual: {mode}. Use /mode fast|plan|auto.',
  'chat.scope_set': '✅ Escopo: {scope}',
  'chat.rag_note':
      'O RAG é definido ao iniciar: use --rag ou --no-rag em `shepherd ai`.',
  'chat.unknown_command': 'Comando desconhecido. Digite /help.',
  'chat.switch_cancelled': 'ℹ️  Troca cancelada. Mantido: {model}.',
  'chat.model_unknown':
      '❌ Opção ou modelo não reconhecido. Digite "/model" para ver a lista.',
  'chat.model_changed': '✅ Modelo alterado para: {model} ({provider})',
  'chat.help':
      '  /plan | /auto | /fast       muda o modo (com texto depois, já pergunta)\n  /executar [auto]            executa o plano: arquivos (você confirma) e comandos de terminal (você confirma cada um)\n  /model [nome]               troca o modelo ou o provedor\n  /projects a,b               limita o contexto e os arquivos a estes projetos\n  sair                        encerra\nCtrl+C durante uma resposta interrompe só a resposta.',
  'chat.hint_full':
      '/plan só planeja · /executar executa o plano · /auto grava na hora · /fast pergunta antes · /model · /projects · /help · sair',
  'chat.hint_short':
      '/plan /executar /auto /fast · /model · /projects · /help · sair',
  'chat.help_mode_cmd': '/mode [fast|plan|auto]',
  'installer.env_missing':
      '{env} aponta para um arquivo que não existe: {path}',
  'installer.download_failed':
      'Não foi possível baixar o motor de IA ({e}). Conecte-se à internet e tente de novo.',
  'installer.no_package':
      'Ainda não há motor de IA publicado para este computador ({platform}).',
  'installer.unknown_platform': 'plataforma desconhecida',
  'installer.downloading': 'Baixando o motor de IA {version}...',
  'installer.feed_status': 'O servidor de atualizações respondeu {status}.',
  'installer.bad_signature':
      'A assinatura da lista de versões do motor não confere. Nada foi instalado.',
  'installer.bad_feed': 'Lista de versões inválida: {detail}',
  'installer.download_status': 'Não foi possível baixar o motor ({status}).',
  'installer.bad_hash':
      'O arquivo baixado não confere com o hash da lista assinada. Nada foi instalado.',
  'installer.server_status': 'O servidor respondeu {status}.',
  'installer.retrying': 'Conexão instável, tentando de novo ({i}/{max})...',
  'installer.no_binary': 'O pacote do motor não traz {exe}.',
  'rpc.engine_exited': 'O motor de IA encerrou de forma inesperada.',
  'help.projects':
      'Limita o contexto (e os arquivos que a IA pode alterar) a estes projetos, pastas na raiz do workspace. Vazio = workspace inteiro.',
  'help.model': 'Modelo de IA (ex: gemini-3.8-flash, gpt-4o, llama3.1).',
  'help.provider': 'Provedor de IA: gemini, openai, anthropic ou ollama.',
  'help.mode':
      'fast (pergunta antes de gravar), plan (só planeja) ou auto (grava direto).',
  'help.plan': 'Atalho para --mode plan.',
  'help.auto': 'Atalho para --mode auto.',
  'help.rag': 'Liga ou desliga o contexto do workspace (ligado por padrão).',
  'help.file': 'Anexa o conteúdo de arquivos locais à pergunta.',
  'help.profile': 'Perfil de modelo: advanced, medium ou local.',
  'help.local': 'Usa o perfil de modelo local.',
  'help.engine_path':
      'Mostra onde está o motor de IA (instalando-o se faltar).',
  'help.update_engine': 'Procura agora uma versão nova do motor de IA.',
  'help.config_sync': 'Sincroniza o catálogo de modelos online.',
  'launcher.usage':
      'Uso: shepherd ai ["sua pergunta"] [-m modelo] [-p provedor] [--plan|--auto] [--projects a,b] [-f arquivo]\n     shepherd ai config [--sync]\n     shepherd ai model [nome_do_modelo]\n     shepherd ai --engine-path | --update-engine',
  'launcher.bad_args': '❌ Erro: {e}\n{usage}',
  'launcher.login_required':
      '❌ Faça login para usar o Shepherd AI: `shepherd login`.',
  'launcher.file_not_found': '⚠️  Arquivo não encontrado: {path}',
  'opt.name_local': 'Local (Ollama)',
  'opt.local':
      'Escolher modelo do Ollama [RAG Ativo / Custo Zero] (Atual: {model}{lan})',
  'opt.openai': '{model} [Econômico / Nuvem]',
  'opt.anthropic': '{model} [Raciocínio / Nuvem]',
  'opt.gemini': '{model} [Rápido / Nuvem]',
  'opt.opencode':
      'Escolher modelo [qwen, deepseek, claude, gpt...] (Atual: {model})',
  'opt.name_lan': 'Servidor Local (LAN)',
  'opt.lan': '{model} [RAG Ativo / LAN] ({url})',
  'dn.gemini': 'Google Gemini (Direto)',
  'dn.openai': 'OpenAI (Direto)',
  'dn.anthropic': 'Anthropic Claude (Direto)',
  'dn.opencode': 'OpenCode Zen (opencode.ai)',
  'dn.ollama': 'Ollama (Local / Rede Local)',
  'dn.lan': 'Servidor Local / Rede Local',
  'models.menu_prompt':
      'Escolha uma opção [1-{n}] ou digite o nome do modelo (ou Enter para cancelar): ',
  'models.title': '🤖 Shepherd AI — Trocar de Modelo / Provedor',
  'models.current': 'Modelo Atual: {model} ({provider})\n',
  'models.options': 'Opções disponíveis:',
  'models.active': '★ (Ativo)',
  'models.cancelled': 'ℹ️  Operação cancelada.\n',
  'models.unknown':
      '❌ Opção ou modelo não reconhecido. Digite "shepherd ai model" para ver a lista.\n',
  'models.default_set':
      '✅ Modelo padrão atualizado para: {model} ({provider})\n',
  'picker.fetching': '🔍 Buscando modelos em {provider}... ',
  'picker.default_list': 'usando a lista padrão.',
  'picker.n_models': '{n} modelo(s).',
  'picker.no_key':
      'ℹ️  Sem chave de API para {provider} (use `shepherd ai config`); mostrando a lista padrão.\n',
  'picker.title': 'Modelos de {provider}:',
  'picker.type_name': '  [m] ✍️ Digitar o nome de outro modelo',
  'picker.choose': 'Escolha [1-{n}] ou [m] (Enter para manter "{model}"): ',
  'picker.model_name': 'Nome do modelo: ',
  'picker.no_option': 'ℹ️  Opção {n} não existe; mantido: {model}.',
  'notice.usage':
      'ℹ️  Relatório de uso: o Shepherd AI envia à conta Shepherd da sua empresa números de uso (provedor, modelo, tokens e duração) para ela acompanhar como a IA é usada. Nunca são enviados perguntas, respostas, nomes de arquivo nem código. Para desligar, use `telemetry: false` em .shepherd/ai_config.yaml. Este aviso aparece uma vez.',
  'diff.new_file': '(novo arquivo)',
  'diff.modification': '(modificação)',
  'diff.more_lines': '  ... mais {n} linhas',
  'diff.too_big':
      '  (arquivo grande demais para comparar linha a linha: {old} → {new} linhas)',
  'diff.no_changes': '  (sem diferenças)',
  'diff.continues': '  ... (diferença continua)',
  'ollama.fetching': '\n🔍 Buscando modelos disponíveis no Ollama ({url})... ',
  'ollama.detected': '{n} modelo(s) detectado(s)!',
  'ollama.offline': 'Ollama offline ou inacessível em {url}.',
  'ollama.lan_tip':
      '💡 Está em outra máquina na rede? Digite {key} para definir IP/porta.\n',
  'ollama.models_title': 'Modelos disponíveis no seu Ollama:',
  'ollama.change_url':
      '  [u] 🌐 Alterar IP / URL do Ollama na rede (atual: {url})',
  'ollama.choose':
      'Escolha um modelo [1-{n}], [u] para IP/URL (Enter para manter "{model}"): ',
  'ollama.ask_url':
      '\nDigite o IP ou hostname do Ollama na rede (ex: http://192.168.1.50:11434) [{url}]: ',
  'ollama.url_updated': '✅ Endereço do Ollama atualizado para: {url}',
  'opencode.setup_title': 'Configuração do OpenCode Zen (opencode.ai)',
};
