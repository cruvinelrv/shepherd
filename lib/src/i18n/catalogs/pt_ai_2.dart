// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> ptAi2 = {
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
  'opencode.intro':
      'O OpenCode Zen permite acesso a múltiplos modelos de ponta com uma única chave de API.',
  'opencode.get_key':
      'Obtenha sua chave em: https://opencode.ai ou https://opencode.ai/zen\n',
  'opencode.ask_key':
      'Digite sua chave de API do OpenCode (ou Enter para cancelar): ',
  'opencode.cancelled': 'ℹ️  Configuração cancelada.\n',
  'opencode.key_saved':
      '✅ Chave de API do OpenCode salva em .shepherd/ai_config.yaml!\n',
  'opencode.fetching':
      '🔍 Buscando catálogo de modelos no OpenCode Zen ({url})... ',
  'opencode.n_models': '{n} modelo(s) disponível(is)!\n',
  'opencode.default_catalog': 'Utilizando catálogo padrão do OpenCode Zen.\n',
  'opencode.models_title': 'Modelos disponíveis no OpenCode Zen:',
  'opencode.update_key': '  [k] 🔑 Atualizar chave de API do OpenCode',
  'opencode.type_model': '  [m] ✍️ Digitar manualmente outro nome de modelo',
  'opencode.choose':
      'Escolha uma opção [1-{n}], [k] chave, [m] outro (Enter para manter "{model}"): ',
  'opencode.new_key': '\nDigite a nova chave de API do OpenCode: ',
  'opencode.key_updated': '✅ Chave de API atualizada com sucesso!\n',
  'opencode.ask_model':
      '\nDigite o ID do modelo no OpenCode (ex: deepseek-v4-pro, qwen3.8-max): ',
};
