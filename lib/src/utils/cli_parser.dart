import 'package:args/args.dart';

ArgParser buildShepherdArgParser() {
  final parser = ArgParser();

  // Direct commands
  parser.addCommand('analyze');
  parser.addCommand('clean');
  parser.addCommand('project');
  parser.addCommand('config');
  parser.addCommand('list');
  parser.addCommand('delete');
  parser.addCommand('add-owner');
  parser.addCommand('export-yaml');
  parser.addCommand('changelog');
  final flowCommand = parser.addCommand('flow');
  flowCommand.addOption('bump',
      abbr: 'p',
      help: 'Version bump type (keep, patch, minor, major)',
      allowed: ['keep', 'patch', 'minor', 'major']);
  flowCommand.addOption('base',
      abbr: 'b',
      help:
          'Base tag/commit to compare against (default: auto-detected previous tag)');
  flowCommand.addFlag('interactive',
      abbr: 'i', help: 'Prompt for inputs if not specified', defaultsTo: true);
  flowCommand.addFlag('help',
      abbr: 'h', help: 'Show help message', negatable: false);
  parser.addCommand('gitrecover');
  parser.addCommand('auto-update');
  final updateCmd = parser.addCommand('update');
  updateCmd.addFlag('check',
      negatable: false, help: 'Only check and show the command; do not run it.');
  updateCmd.addFlag('yes',
      abbr: 'y', negatable: false, help: 'Do not ask before running the update.');
  parser.addCommand('help');
  parser.addCommand('init');

  final loginCommand = parser.addCommand('login');
  loginCommand.addOption('apikey',
      abbr: 'a', help: 'The API Key for Shepherd Union');

  parser.addCommand('version');
  parser.addCommand('about');
  parser.addCommand('pull');
  parser.addCommand('shell');
  parser.addCommand('mcp');

  final testCommand = parser.addCommand('test');
  testCommand.addOption('story',
      abbr: 's', help: 'Story/Feature ID to generate tests for');

  final tagCommand = parser.addCommand('tag');
  tagCommand.addCommand('gen').addOption('story',
      abbr: 's', help: 'Story/Feature ID to generate tag stubs for');

  final elementCommand = parser.addCommand('element');
  elementCommand.addCommand('add');
  elementCommand.addCommand('list');

  final storyCommand = parser.addCommand('story');
  storyCommand.addCommand('add');
  storyCommand.addCommand('list');

  final taskCommand = parser.addCommand('task');
  taskCommand.addCommand('add');
  taskCommand.addCommand('list');

  final aiCommand = parser.addCommand('ai');
  aiCommand.addOption('model',
      abbr: 'm',
      help: 'Modelo de IA a ser utilizado.');
  aiCommand.addOption('provider',
      abbr: 'p',
      help: 'Provedor de IA (gemini, openai, anthropic, ollama, local_ai).');
  aiCommand.addOption('scope',
      abbr: 's',
      allowed: ['project', 'workspace'],
      defaultsTo: 'project',
      help: 'project: só o diretório atual. workspace: inclui todos os '
          'projetos do .shepherd/workspace.yaml.');
  aiCommand.addOption('mode',
      allowed: ['fast', 'plan', 'auto'],
      defaultsTo: 'fast',
      help: 'Modo de execução.');
  aiCommand.addOption('tier',
      allowed: ['fast', 'deep'],
      defaultsTo: 'fast',
      help: 'Nível de atividade.');
  aiCommand.addMultiOption('file',
      abbr: 'f',
      help: 'Anexa arquivos locais ao contexto.');
  aiCommand.addFlag('jsonl',
      negatable: false,
      help: 'Modo máquina: requisições JSON no stdin, eventos JSON no stdout.');
  aiCommand.addMultiOption('projects',
      splitCommas: true,
      help: 'Restringe o contexto aos projetos (pastas) informados.');
  aiCommand.addFlag('rag',
      negatable: true,
      help: 'Ativa ou desativa o contexto via RAG.');
  aiCommand.addFlag('plan', negatable: false, help: 'Atalho para --mode plan.');
  aiCommand.addFlag('auto', negatable: false, help: 'Atalho para --mode auto.');
  aiCommand.addFlag('deep', negatable: false, help: 'Atalho para --tier deep.');
  aiCommand.addFlag('advanced',
      negatable: false,
      help: 'Use advanced model profile (EN).');
  aiCommand.addFlag('avancado',
      negatable: false,
      help: 'Usa o perfil de modelo avançado (PT).');
  aiCommand.addFlag('avanzado',
      negatable: false,
      help: 'Usa el perfil de modelo avanzado (ES).');
  aiCommand.addFlag('medium',
      negatable: false,
      help: 'Use medium model profile (EN).');
  aiCommand.addFlag('medio',
      negatable: false,
      help: 'Usa o perfil de modelo médio (PT / ES).');
  aiCommand.addFlag('local',
      negatable: false,
      help: 'Use local/LAN model profile (EN / PT / ES).');
  aiCommand.addOption('profile',
      help: 'Activate model profile (advanced, medium, local).');

  final aiConfigCommand = aiCommand.addCommand('config');
  aiConfigCommand.addFlag('sync',
      abbr: 's',
      negatable: false,
      help: 'Sincroniza catálogo de modelos online.');
  aiConfigCommand.addOption('provider',
      abbr: 'p',
      help: 'Provedor para configurar diretamente.');

  final aiIndexCommand = aiCommand.addCommand('index');
  aiIndexCommand.addFlag('force', abbr: 'f', negatable: false, help: 'Force re-indexing (EN).');
  aiIndexCommand.addFlag('forcar', negatable: false, help: 'Forçar re-indexação (PT).');
  aiIndexCommand.addFlag('forzar', negatable: false, help: 'Forzar reindexación (ES).');
  aiIndexCommand.addFlag('status', abbr: 's', negatable: false, help: 'Show index status (EN/PT).');
  aiIndexCommand.addFlag('estado', negatable: false, help: 'Estado del índice (ES).');
  aiIndexCommand.addFlag('clear', negatable: false, help: 'Clear vector store (EN).');
  aiIndexCommand.addFlag('limpar', negatable: false, help: 'Limpar base vetorial (PT).');
  aiIndexCommand.addFlag('limpiar', negatable: false, help: 'Limpiar base vectorial (ES).');
  aiIndexCommand.addOption('project', abbr: 'p', help: 'Project to index (EN).');
  aiIndexCommand.addOption('projeto', help: 'Projeto a indexar (PT/ES).');

  final aiIndexarCommand = aiCommand.addCommand('indexar');
  aiIndexarCommand.addFlag('force', abbr: 'f', negatable: false);
  aiIndexarCommand.addFlag('forcar', negatable: false);
  aiIndexarCommand.addFlag('forzar', negatable: false);
  aiIndexarCommand.addFlag('status', abbr: 's', negatable: false);
  aiIndexarCommand.addFlag('estado', negatable: false);
  aiIndexarCommand.addFlag('clear', negatable: false);
  aiIndexarCommand.addFlag('limpar', negatable: false);
  aiIndexarCommand.addFlag('limpiar', negatable: false);
  aiIndexarCommand.addOption('project', abbr: 'p');
  aiIndexarCommand.addOption('projeto');

  // Groups for interactive menus
  parser.addCommand('domains');
  parser.addCommand('deploy');
  parser.addCommand('tools');

  return parser;
}
