// GENERATED from the catalog source; do not edit by hand.
const Map<String, String> ptCli1 = {
  'install.homebrew': 'Homebrew (shepherd_cli)',
  'install.script': 'script de instalação (curl / PowerShell)',
  'install.studio': 'embutido no Shepherd Studio',
  'install.source': 'código-fonte (dart run)',
  'install.unknown': 'não identificado',
  'model.gone':
      'Esse modelo não está mais disponível para a sua conta. Digite "/model" (ou `shepherd ai model`) e escolha outro na lista.',
  'sync.conflict': '❌ Conflito de Sincronização!',
  'sync.newer':
      'A nuvem possui informações mais recentes (Nuvem: {server} > Local: {local}).',
  'sync.pull':
      'Faça um `git pull` para obter a versão mais recente antes de rodar `shepherd gen` novamente.',
  'update.not_pub': 'esta instalação não é do pub.dev',
  'update.header': 'Shepherd CLI {version} — instalação: {method}',
  'update.no_check':
      'Não consegui consultar a versão mais recente (sem internet?). Tente de novo mais tarde.',
  'update.up_to_date': '✅ Você já está na versão mais recente ({version}).',
  'update.available': '📦 Nova versão disponível: {current} → {newest}',
  'update.news': '   Novidades: {url}',
  'update.studio':
      'Este CLI vem dentro do Shepherd Studio: atualize o Studio para receber a nova versão.',
  'update.source':
      'Você está rodando do código-fonte: atualize o repositório (git pull && dart pub get).',
  'update.unknown':
      'Não sei como este CLI foi instalado. Use o comando do seu caso:',
  'update.to_update': 'Para atualizar, rode:',
  'update.brew_lag':
      'Se o Homebrew disser que já está atualizado, a fórmula ainda não recebeu a {newest}: tente mais tarde.',
  'update.running': '⏳ Atualizando...',
  'update.done': '✅ Pronto. Abra um novo terminal para usar a {newest}.',
  'update.failed':
      '❌ A atualização falhou (código {code}). Rode manualmente: {command}',
  'update.ask': '\nAtualizar agora? [s/N]: ',
  'clean.home1': '⚠️ Você está no diretório raiz do usuário (~).',
  'clean.home2':
      '👉 Navegue até a pasta do seu projeto/workspace antes de executar o clean (ex: cd dev/meu_projeto).\n',
  'pr.gh_missing':
      'GitHub CLI (gh) não encontrado. Instale pelo menu de ferramentas do Shepherd.',
  'pr.az_login':
      'Você não está logado no Azure CLI. A PR será salva no banco de dados para envio posterior.',
  'pr.az_saved':
      'PR salva no banco de dados. Você pode reenviar quando estiver logado no Azure.',
  'toggle.exists': 'Já existe um Feature Toggle com o nome "{name}".',
  'toggle.not_found': 'Feature toggle não encontrado com id: {id}',
  'cl.start': '🧹 Iniciando o Shepherd Clean...\n',
  'cl.ws_project': '📍 Projeto do workspace detectado: "{name}"',
  'cl.target': '📍 Diretório alvo: {path}\n',
  'cl.target_missing': '❌ Diretório ou projeto alvo não encontrado: {arg}\n',
  'cl.current_only': '📍 Limpando só o projeto atual ({path})...',
  'cl.no_pubspec_here':
      '❌ Nenhum pubspec.yaml encontrado no diretório atual ({path}).',
  'cl.manifest':
      '🏢 Manifesto de workspace detectado: "{name}" ({n} projetos registrados)',
  'cl.searching': '🔍 Procurando arquivos pubspec.yaml com segurança...',
  'cl.none_found': '❌ Nenhum pubspec.yaml encontrado em "{path}".',
  'cl.found': '📦 {n} projeto(s) para limpar',
  'cl.cleaning': '--- 🧽 Limpando: {name} ({path}) ---',
  'cl.rm_lock': '🗑️  pubspec.lock removido',
  'cl.rm_lock_fail': '⚠️  Não foi possível remover o pubspec.lock: {e}',
  'cl.rm_build': '🗑️  Diretório build/ removido',
  'cl.rm_build_fail': '⚠️  Não foi possível remover build/: {e}',
  'cl.rm_dart_tool': '🗑️  Diretório .dart_tool/ removido',
  'cl.rm_dart_tool_fail': '⚠️  Não foi possível remover .dart_tool/: {e}',
  'cl.flutter_clean': '🔧 Executando flutter clean...',
  'cl.flutter_clean_ok': '✅ Flutter clean concluído',
  'cl.flutter_clean_issues': '⚠️  O flutter clean teve problemas: {e}',
  'cl.flutter_clean_fail': '⚠️  Não foi possível executar o flutter clean: {e}',
  'cl.flutter_get': '📥 Executando flutter pub get...',
  'cl.dart_get': '📥 Executando dart pub get...',
  'cl.deps_ok': '✅ Dependências restauradas',
  'cl.get_issues': '⚠️  O pub get teve problemas: {e}',
  'cl.flutter_get_fail': '⚠️  Não foi possível executar o pub get: {e}',
  'cl.dart_get_fail': '⚠️  Não foi possível executar o dart pub get: {e}',
  'cl.done': '🎉 Limpeza concluída para {n} projeto(s)!',
  'qi.title': '🐑 Novo workspace Shepherd',
  'qi.intro':
      'Um workspace é uma pasta com as configurações em .shepherd/; cada projeto dentro dela tem o próprio git. Poucas perguntas, cada uma com um padrão (Enter).',
  'qi.already': 'Já existe um workspace Shepherd nesta pasta.',
  'qi.continue_anyway':
      'Configurar de novo e sobrescrever as configurações? [s/N]: ',
  'qi.cancelled': 'Nada foi alterado.',
  'qi.ask_name': 'Nome do workspace',
  'qi.bad_name': 'O nome não pode ser vazio nem ter / ou \\.',
  'qi.new_folder':
      'Criar uma pasta nova "{name}" aqui e configurar lá? [S/n] (n = usar esta pasta): ',
  'qi.ask_user': 'Seu nome',
  'qi.ask_email': 'Seu e-mail',
  'qi.need_user': 'É preciso um nome. Use --user "Nome Sobrenome".',
  'qi.ask_repo': 'Onde o código vai ficar? (github / azure / later)',
  'qi.bad_repo': 'Digite github, azure ou later.',
  'qi.ask_github':
      'Seu usuário do GitHub (para pull requests, Enter para pular)',
  'qi.done': '✅ O workspace "{name}" está pronto.',
  'qi.sum_where': 'Pasta:        {path}',
  'qi.sum_user': 'Você:         {user} <{email}>',
  'qi.sum_env':
      'Ambiente:     PRD → {trunk} (trunk based development: uma branch)',
  'qi.sum_repo': 'Repositório:  {repo}',
  'qi.repo_later': 'ainda não definido (pull requests desligados)',
  'qi.change':
      'Mude qualquer coisa depois em .shepherd/ (environments.yaml, config.yaml) ou com `shepherd config`.',
  'login.global':
      '🔑 Este login vale para todas as pastas (salvo em ~/.shepherd/session.yaml).',
  'login.no_folder':
      'Nenhum workspace nesta pasta, então não há projeto para ligar. Rode `shepherd init` (ou `shepherd` e escolha uma opção) aqui quando quiser um.',
  'mcp.none_global':
      'ℹ️  Nenhum servidor MCP configurado no workspace ou globalmente.',
  'mcp.edit': 'Edite o arquivo {file} para adicionar servidores MCP.',
  'mcp.example': 'Exemplo:',
  'mcp.configured': '🔌 Servidores MCP Configurados ({n}):',
  'mcp.command_label': 'comando',
  'mcp.connecting': '    Conectando e buscando ferramentas... ',
  'mcp.ok_tools': '({ms}ms, {n} ferramentas)',
  'mcp.failed': 'FALHOU',
};
