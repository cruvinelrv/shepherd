import 'dart:io';
import 'package:shepherd/src/utils/ansi_colors.dart';
import 'package:shepherd/src/utils/ai_i18n_helper.dart';
import 'package:shepherd/src/version.dart';
import '../../data/models/shell_session_model.dart';
import '../../domain/services/workspace_scaffold_service.dart';
import 'shepherd_runner.dart';

/// Interactive Shell (REPL) for Shepherd CLI.
/// Provides a continuous interactive environment where developers can run commands,
/// manage sessions, and talk to Shepherd AI without exiting to the system shell.
class ShepherdShell {
  static String activeMode = 'fast';
  static String activeTier = 'fast';
  static String activeProfile = 'medium';

  static Future<void> start() async {
    // Scaffold standard workspace & project YAML files if not present
    WorkspaceScaffoldService.ensureShepherdFiles();

    var session = ShellSessionModel.loadFromWorkspace();

    _printWelcomeBanner(session);

    while (true) {
      final prompt = _buildPrompt(session);
      stdout.write(prompt);

      final input = stdin.readLineSync();
      if (input == null) {
        // EOF / Ctrl+D
        print('');
        break;
      }

      final trimmed = input.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final args = parseCommandLine(trimmed);
      if (args.isEmpty) continue;

      final command = args.first.toLowerCase();

      // Built-in Shell commands
      if (command == 'exit' || command == 'quit' || command == 'q') {
        print('\n👋 Saindo do Shepherd Shell. Até logo!\n');
        break;
      }

      if (command == 'clear' || command == 'cls') {
        _clearScreen();
        _printWelcomeBanner(session, compact: true);
        continue;
      }

      if (command == 'status' || command == 'whoami' || command == 'session') {
        session = ShellSessionModel.loadFromWorkspace();
        _printStatus(session);
        continue;
      }

      if (command == 'advanced' || command == 'avancado' || command == 'avanzado') {
        activeProfile = 'advanced';
        activeTier = 'deep';
        print('🧠 ${AnsiColors.brightGreen}Perfil alterado para Avançado / Advanced / Avanzado (Deep)${AnsiColors.reset}');
        continue;
      }

      if (command == 'medium' || command == 'medio') {
        activeProfile = 'medium';
        activeTier = 'fast';
        print('⚡ ${AnsiColors.brightGreen}Perfil alterado para Médio / Medium / Medio (Fast)${AnsiColors.reset}');
        continue;
      }

      if (command == 'local') {
        activeProfile = 'local';
        print('🏡 ${AnsiColors.brightGreen}Perfil alterado para Local (Offline / LAN / Zero Cost)${AnsiColors.reset}');
        continue;
      }

      if (command == 'model' || command == 'engine') {
        session = ShellSessionModel.loadFromWorkspace();
        final model = activeTier == 'deep' ? 'gemini-1.5-pro' : (session.aiModel ?? 'gemini-2.5-flash');
        final provider = session.aiProvider ?? 'Shepherd Platform';
        print('\n${AnsiColors.bold}${AnsiColors.brightCyan}🤖 Configuração do Motor LLM:${AnsiColors.reset}');
        print('  Provedor: ${AnsiColors.bold}$provider${AnsiColors.reset}');
        print('  Modelo:   ${AnsiColors.brightGreen}$model${AnsiColors.reset}');
        print('  Perfil:   ${AnsiColors.brightCyan}$activeProfile${AnsiColors.reset} (use `advanced`, `medium` ou `local`)');
        print('  Tier:     ${AnsiColors.brightYellow}$activeTier${AnsiColors.reset} (use `tier fast` ou `tier deep`)');
        print('  Modo:     ${AnsiColors.brightCyan}$activeMode${AnsiColors.reset} (use `mode fast`, `mode plan` ou `mode auto`)\n');
        continue;
      }

      if (command == 'mode') {
        if (args.length > 1) {
          final target = args[1].toLowerCase();
          if (['fast', 'plan', 'auto'].contains(target)) {
            activeMode = target;
            print('⚡ Modo alterado para [${AnsiColors.brightCyan}$activeMode${AnsiColors.reset}]');
          } else {
            print('Modos válidos: fast, plan, auto');
          }
        } else {
          print('Modo atual: ${AnsiColors.brightCyan}$activeMode${AnsiColors.reset} (opções: fast, plan, auto)');
        }
        continue;
      }

      if (command == 'tier') {
        if (args.length > 1) {
          final target = args[1].toLowerCase();
          if (['fast', 'deep'].contains(target)) {
            activeTier = target;
            print('🧠 Tier alterado para [${AnsiColors.brightCyan}$activeTier${AnsiColors.reset}]');
          } else {
            print('Tiers válidos: fast, deep');
          }
        } else {
          print('Tier atual: ${AnsiColors.brightCyan}$activeTier${AnsiColors.reset} (opções: fast, deep)');
        }
        continue;
      }

      if (command == 'help' || command == 'ajuda' || command == 'ayuda' || command == '?') {
        _printShellHelp();
        continue;
      }

      if (command == 'index' || command == 'indexar') {
        final subArgs = ['ai', 'index', ...args.sublist(1)];
        await executeShepherdCommand(subArgs, inShell: true);
        continue;
      }

      const knownCommands = {
        'ai', 'clean', 'changelog', 'flow', 'deploy', 'test', 'login', 'init',
        'pull', 'sync', 'format', 'analyze', 'status', 'whoami', 'session',
        'mode', 'tier', 'model', 'engine', 'mcp', 'menu', 'help', '?', 'clear', 'cls',
        'exit', 'quit', 'linter', 'azurecli', 'version', 'about', 'tag', 'recover',
        'advanced', 'avancado', 'avanzado', 'medium', 'medio', 'local', 'ajuda', 'ayuda',
        'index', 'indexar',
      };

      List<String> effectiveArgs = args;
      if (!knownCommands.contains(command)) {
        // Natural language query or @file mention: automatically route to ai
        effectiveArgs = ['ai', trimmed, '--mode', activeMode, '--tier', activeTier, '--profile', activeProfile];
      } else if (command == 'ai' && args.length > 1 && !args.contains('--mode') && !args.contains('--plan') && !args.contains('--auto')) {
        effectiveArgs = [...args, '--mode', activeMode, '--tier', activeTier, '--profile', activeProfile];
      }

      // Execute Shepherd command
      try {
        await executeShepherdCommand(effectiveArgs, inShell: true);

        // If command was login, pull, or ai config, refresh the session state immediately
        if (command == 'login' || command == 'init' || command == 'pull' || command == 'ai') {
          session = ShellSessionModel.loadFromWorkspace();
        }
      } catch (e, stack) {
        print('\n${AnsiColors.brightRed}❌ Erro durante execução do comando:${AnsiColors.reset} $e');
        if (Platform.environment['SHEPHERD_DEBUG'] == 'true') {
          print(stack);
        }
      }
      print('');
    }
  }

  static String _buildPrompt(ShellSessionModel session) {
    final buffer = StringBuffer();
    buffer.write('${AnsiColors.brightBlue}shepherd${AnsiColors.reset} ');

    final displayWorkspace = session.workspaceName ?? session.projectName;
    buffer.write('${AnsiColors.brightBlack}[${AnsiColors.brightYellow}$displayWorkspace${AnsiColors.brightBlack}]${AnsiColors.reset}');

    buffer.write(' ${AnsiColors.brightMagenta}($activeMode)${AnsiColors.reset}');

    if (session.userName != null && session.userName!.isNotEmpty) {
      buffer.write(' ${AnsiColors.brightGreen}(${session.userName})${AnsiColors.reset}');
    }

    buffer.write(' ${AnsiColors.brightCyan}>${AnsiColors.reset} ');
    return buffer.toString();
  }

  static void _printWelcomeBanner(ShellSessionModel session, {bool compact = false}) {
    final lang = AiI18nHelper.detectSystemLanguage();
    final activeModelName = activeTier == 'deep' ? 'gemini-1.5-pro' : (session.aiModel ?? 'gemini-2.5-flash');
    final displayWorkspace = session.workspaceName ?? session.projectName;

    String authConnected;
    String authOffline;
    String offlineNotice;
    String helpTip;

    switch (lang) {
      case ShepherdLang.pt:
        authConnected = 'Conectado (${session.userName ?? session.environment ?? 'Ativo'})';
        authOffline = 'Modo Offline (https://shepherdplatform.com)';
        offlineNotice = '⚡ Ferramentas de desenvolvimento (clean, flow, changelog) funcionam 100% offline.';
        helpTip = '💡 Digite comandos diretamente, use ${AnsiColors.brightCyan}@arquivo${AnsiColors.reset} no prompt para contexto, ou ${AnsiColors.brightCyan}ajuda / help${AnsiColors.reset}.\n';
        break;
      case ShepherdLang.es:
        authConnected = 'Conectado (${session.userName ?? session.environment ?? 'Activo'})';
        authOffline = 'Modo Offline (https://shepherdplatform.com)';
        offlineNotice = '⚡ Herramientas de desarrollo (clean, flow, changelog) funcionan 100% offline.';
        helpTip = '💡 Escriba comandos directamente, use ${AnsiColors.brightCyan}@archivo${AnsiColors.reset} en el prompt para contexto, o ${AnsiColors.brightCyan}ayuda / help${AnsiColors.reset}.\n';
        break;
      case ShepherdLang.en:
        authConnected = 'Connected (${session.userName ?? session.environment ?? 'Active'})';
        authOffline = 'Offline Mode (https://shepherdplatform.com)';
        offlineNotice = '⚡ Development tools (clean, flow, changelog) work 100% offline.';
        helpTip = '💡 Type commands directly, use ${AnsiColors.brightCyan}@file${AnsiColors.reset} in the prompt for context, or ${AnsiColors.brightCyan}help${AnsiColors.reset}.\n';
        break;
    }

    if (!compact) {
      const boxWidth = 68;
      print('\n${AnsiColors.brightBlue}╭${'─' * boxWidth}╮${AnsiColors.reset}');
      print(_formatBoxLine('  🐑 ${AnsiColors.bold}Shepherd Interactive Shell (REPL)${AnsiColors.reset} v$shepherdVersion', boxWidth));
      print(_formatBoxLine('  by Marmelotech (https://marmelotech.com.br)', boxWidth));
      print('${AnsiColors.brightBlue}├${'─' * boxWidth}┤${AnsiColors.reset}');
      
      final authStr = session.isAuthenticated
          ? '🔑 Auth:      $authConnected'
          : '🌐 Auth:      $authOffline';

      print(_formatBoxLine('  🏢 Workspace: $displayWorkspace', boxWidth));
      print(_formatBoxLine('  $authStr', boxWidth));
      print(_formatBoxLine('  🤖 AI:        $activeModelName [RAG: Local | Profile: $activeProfile | Mode: $activeMode]', boxWidth));
      print('${AnsiColors.brightBlue}╰${'─' * boxWidth}╯${AnsiColors.reset}');
      print(offlineNotice);
      print(helpTip);
    } else {
      final engineLabel = lang == ShepherdLang.en ? 'Engine' : 'Motor';
      print('${AnsiColors.brightBlue}🐑 Shepherd Shell v$shepherdVersion [$displayWorkspace] ($engineLabel: $activeModelName | RAG: Local)${AnsiColors.reset}\n');
    }
  }

  static void _printStatus(ShellSessionModel session) {
    final activeModelName = activeTier == 'deep' ? 'gemini-1.5-pro' : (session.aiModel ?? 'gemini-2.5-flash');
    final provider = session.aiProvider ?? 'Shepherd Platform (Marmelotech)';
    final displayWorkspace = session.workspaceName ?? session.projectName;
    print('\n${AnsiColors.bold}${AnsiColors.brightCyan}📌 Shepherd Shell Status:${AnsiColors.reset}');
    print('  ${AnsiColors.bold}Workspace:${AnsiColors.reset}      $displayWorkspace (${Directory.current.path})');
    print('  ${AnsiColors.bold}Usuário Ativo:${AnsiColors.reset}  ${session.userName ?? 'Nenhum usuário selecionado'} ${session.userEmail != null ? '(${session.userEmail})' : ''}');
    print('  ${AnsiColors.bold}Autenticação:${AnsiColors.reset}   ${session.isAuthenticated ? '${AnsiColors.brightGreen}Autenticado [${session.environment ?? 'prod'}]${AnsiColors.reset}' : '${AnsiColors.brightYellow}Não autenticado (use `login`)${AnsiColors.reset}'}');
    print('  ${AnsiColors.bold}Motor LLM:${AnsiColors.reset}      ${AnsiColors.brightCyan}$activeModelName${AnsiColors.reset} ($provider)');
    print('  ${AnsiColors.bold}Contexto RAG:${AnsiColors.reset}  ${AnsiColors.brightGreen}Local (Ativo)${AnsiColors.reset}');
    print('  ${AnsiColors.bold}Nível IA:${AnsiColors.reset}       Tier: ${AnsiColors.brightYellow}$activeTier${AnsiColors.reset} | Modo: ${AnsiColors.brightCyan}$activeMode${AnsiColors.reset}\n');
  }

  static void _printShellHelp() {
    print('''
${AnsiColors.bold}${AnsiColors.brightCyan}Comandos do Shepherd Shell (REPL):${AnsiColors.reset}

  ${AnsiColors.brightGreen}<pergunta | comando>${AnsiColors.reset} Digite diretamente sua pergunta ou comando para a IA
  ${AnsiColors.brightGreen}ai <prompt>${AnsiColors.reset}          Envia uma instrução direta para o Shepherd AI
  ${AnsiColors.brightGreen}@caminho/arquivo${AnsiColors.reset}     Mencione arquivos no prompt para a IA ler (ex: "explique @lib/main.dart")
  ${AnsiColors.brightGreen}advanced / avancado${AnsiColors.reset}  Alterna para o perfil Avançado (Claude 3.7 Sonnet / GPT-4o / o3-mini)
  ${AnsiColors.brightGreen}medium / medio${AnsiColors.reset}       Alterna para o perfil Médio (Gemini 2.5 Flash / GPT-4o-mini)
  ${AnsiColors.brightGreen}local${AnsiColors.reset}                Alterna para o perfil Local gratuito (Ollama / LM Studio)
  ${AnsiColors.brightGreen}index / indexar${AnsiColors.reset}      Indexa o workspace localmente em SQLite para RAG vetorial offline
  ${AnsiColors.brightGreen}ai --plan <goal>${AnsiColors.reset}     Gera plano de ação com visualização de Diff antes de aplicar
  ${AnsiColors.brightGreen}ai --auto <goal>${AnsiColors.reset}     Executa plano e aplica alterações de arquivo autonomamente
  ${AnsiColors.brightGreen}model / engine${AnsiColors.reset}       Exibe detalhes do motor LLM ativo, perfil e provedor
  ${AnsiColors.brightGreen}mcp [list|status|call]${AnsiColors.reset} Gerencia conexões e executa ferramentas via Model Context Protocol
  ${AnsiColors.brightGreen}mode <fast|plan|auto>${AnsiColors.reset} Alterna o modo de execução padrão do Shell
  ${AnsiColors.brightGreen}tier <fast|deep>${AnsiColors.reset}      Alterna entre modelo rápido (flash) e raciocínio profundo (pro)
  ${AnsiColors.brightGreen}clean${AnsiColors.reset}                Limpa os projetos / microfrontends do workspace (offline)
  ${AnsiColors.brightGreen}login${AnsiColors.reset}                Autentica na Shepherd Platform e sincroniza IA
  ${AnsiColors.brightGreen}changelog${AnsiColors.reset}            Gera ou atualiza o CHANGELOG.md automaticamente
  ${AnsiColors.brightGreen}flow${AnsiColors.reset}                 Executa o fluxo de release TBD (bump + changelog + tag)
  ${AnsiColors.brightGreen}deploy${AnsiColors.reset}               Gerencia deploys e releases
  ${AnsiColors.brightGreen}test${AnsiColors.reset}                 Gera ou executa testes
  ${AnsiColors.brightGreen}status / whoami${AnsiColors.reset}      Exibe informações do projeto atual, usuário e IA
  ${AnsiColors.brightGreen}clear / cls${AnsiColors.reset}          Limpa a tela do terminal
  ${AnsiColors.brightGreen}menu${AnsiColors.reset}                 Abre o menu interativo numérico tradicional
  ${AnsiColors.brightGreen}help / ajuda / ayuda${AnsiColors.reset} Exibe esta lista de comandos
  ${AnsiColors.brightGreen}exit / quit${AnsiColors.reset}          Sai do Shepherd Shell
''');
  }

  static void _clearScreen() {
    if (Platform.isWindows) {
      stdout.write('\x1B[2J\x1B[0f');
    } else {
      stdout.write('\x1B[2J\x1B[3J\x1B[H');
    }
  }

  static String _formatBoxLine(String content, int boxWidth) {
    final w = _visualWidth(content);
    final pad = (boxWidth - w).clamp(0, 200);
    return '${AnsiColors.brightBlue}│${AnsiColors.reset}$content${' ' * pad}${AnsiColors.brightBlue}│${AnsiColors.reset}';
  }

  static int _visualWidth(String str) {
    final clean = str.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
    int width = 0;
    for (final rune in clean.runes) {
      if (rune >= 0x1F300 ||
          (rune >= 0x1100 && rune <= 0x11FF) ||
          (rune >= 0x2E80 && rune <= 0x9FFF) ||
          (rune >= 0xAC00 && rune <= 0xD7AF) ||
          (rune >= 0xF900 && rune <= 0xFAFF) ||
          (rune >= 0xFE10 && rune <= 0xFE19) ||
          (rune >= 0xFE30 && rune <= 0xFE6F) ||
          (rune >= 0xFF00 && rune <= 0xFF60) ||
          (rune >= 0xFFE0 && rune <= 0xFFE6)) {
        width += 2;
      } else {
        width += 1;
      }
    }
    return width;
  }

  /// Parses a command line string into a list of argument tokens,
  /// preserving quoted segments (e.g. `ai "meu prompt com espaços"`).
  static List<String> parseCommandLine(String line) {
    final tokens = <String>[];
    final pattern = RegExp(r'''"([^"]*)"|'([^']*)'|(\S+)''');
    for (final match in pattern.allMatches(line)) {
      if (match.group(1) != null) {
        tokens.add(match.group(1)!);
      } else if (match.group(2) != null) {
        tokens.add(match.group(2)!);
      } else if (match.group(3) != null) {
        tokens.add(match.group(3)!);
      }
    }
    return tokens;
  }
}
