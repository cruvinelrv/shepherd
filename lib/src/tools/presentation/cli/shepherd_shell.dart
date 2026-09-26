import 'dart:io';
import 'package:shepherd/src/utils/ansi_colors.dart';
import 'package:shepherd/src/version.dart';
import '../../data/models/shell_session_model.dart';
import 'shepherd_runner.dart';

/// Interactive Shell (REPL) for Shepherd CLI.
/// Provides a continuous interactive environment where developers can run commands,
/// manage sessions, and talk to Shepherd AI without exiting to the system shell.
class ShepherdShell {
  static String activeMode = 'fast';
  static String activeTier = 'fast';

  static Future<void> start() async {
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

      if (command == 'help' || command == '?') {
        _printShellHelp();
        continue;
      }

      // If user calls 'ai <prompt>' without specifying --mode, automatically inject the shell's activeMode and activeTier
      List<String> effectiveArgs = args;
      if (command == 'ai' && args.length > 1 && !args.contains('--mode') && !args.contains('--plan') && !args.contains('--auto')) {
        effectiveArgs = [...args, '--mode', activeMode, '--tier', activeTier];
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
    buffer.write('${AnsiColors.brightBlack}[${AnsiColors.brightYellow}${session.projectName}${AnsiColors.brightBlack}]${AnsiColors.reset}');

    buffer.write(' ${AnsiColors.brightMagenta}($activeMode)${AnsiColors.reset}');

    if (session.userName != null && session.userName!.isNotEmpty) {
      buffer.write(' ${AnsiColors.brightGreen}(${session.userName})${AnsiColors.reset}');
    }

    buffer.write(' ${AnsiColors.brightCyan}>${AnsiColors.reset} ');
    return buffer.toString();
  }

  static void _printWelcomeBanner(ShellSessionModel session, {bool compact = false}) {
    if (!compact) {
      print('\n${AnsiColors.brightBlue}╭──────────────────────────────────────────────────────────────────────╮${AnsiColors.reset}');
      print('${AnsiColors.brightBlue}│${AnsiColors.reset}  🐑 ${AnsiColors.bold}Shepherd Interactive Shell (REPL)${AnsiColors.reset} v$shepherdVersion${' ' * (37 - shepherdVersion.length)}${AnsiColors.brightBlue}│${AnsiColors.reset}');
      print('${AnsiColors.brightBlue}│${AnsiColors.reset}  by Marmelotech (https://marmelotech.com.br)                        ${AnsiColors.brightBlue}│${AnsiColors.reset}');
      print('${AnsiColors.brightBlue}├──────────────────────────────────────────────────────────────────────┤${AnsiColors.reset}');
      
      final projStr = '📁 Projeto: ${session.projectName}';
      final authStr = session.isAuthenticated
          ? '🔑 Auth: Conectado (${session.userName ?? session.environment ?? 'Ativo'})'
          : '🌐 Auth: Modo Offline (Conta Grátis: https://shepherdplatform.com)';
      final aiStr = '🤖 AI: Shepherd Platform (Mode: $activeMode | Tier: $activeTier)';

      print('${AnsiColors.brightBlue}│${AnsiColors.reset}  $projStr${' ' * (68 - _visibleLength(projStr))}${AnsiColors.brightBlue}│${AnsiColors.reset}');
      print('${AnsiColors.brightBlue}│${AnsiColors.reset}  $authStr${' ' * (68 - _visibleLength(authStr))}${AnsiColors.brightBlue}│${AnsiColors.reset}');
      print('${AnsiColors.brightBlue}│${AnsiColors.reset}  $aiStr${' ' * (68 - _visibleLength(aiStr))}${AnsiColors.brightBlue}│${AnsiColors.reset}');
      print('${AnsiColors.brightBlue}╰──────────────────────────────────────────────────────────────────────╯${AnsiColors.reset}');
      print('⚡ Ferramentas de desenvolvimento (clean, flow, changelog) funcionam 100% offline.');
      print('💡 Digite ${AnsiColors.brightCyan}help${AnsiColors.reset} para comandos, ${AnsiColors.brightCyan}mode <fast|plan|auto>${AnsiColors.reset} para alterar modo, ou ${AnsiColors.brightCyan}exit${AnsiColors.reset} para sair.\n');
    } else {
      print('${AnsiColors.brightBlue}🐑 Shepherd Shell v$shepherdVersion [${session.projectName}] (by Marmelotech - https://marmelotech.com.br)${AnsiColors.reset}\n');
    }
  }

  static void _printStatus(ShellSessionModel session) {
    print('\n${AnsiColors.bold}${AnsiColors.brightCyan}📌 Shepherd Shell Status:${AnsiColors.reset}');
    print('  ${AnsiColors.bold}Projeto:${AnsiColors.reset}        ${session.projectName} (${Directory.current.path})');
    print('  ${AnsiColors.bold}Usuário Ativo:${AnsiColors.reset}  ${session.userName ?? 'Nenhum usuário selecionado'} ${session.userEmail != null ? '(${session.userEmail})' : ''}');
    print('  ${AnsiColors.bold}Autenticação:${AnsiColors.reset}   ${session.isAuthenticated ? '${AnsiColors.brightGreen}Autenticado [${session.environment ?? 'prod'}]${AnsiColors.reset}' : '${AnsiColors.brightYellow}Não autenticado (use `login`)${AnsiColors.reset}'}');
    print('  ${AnsiColors.bold}Shepherd AI:${AnsiColors.reset}    ${AnsiColors.brightGreen}Shepherd Platform (Mode: $activeMode | Tier: $activeTier)${AnsiColors.reset}\n');
  }

  static void _printShellHelp() {
    print('''
${AnsiColors.bold}${AnsiColors.brightCyan}Comandos do Shepherd Shell (REPL):${AnsiColors.reset}

  ${AnsiColors.brightGreen}ai <prompt>${AnsiColors.reset}       Envia uma pergunta diretamente para o Shepherd AI
  ${AnsiColors.brightGreen}ai --plan <goal>${AnsiColors.reset}  Gera plano de ação detalhado antes de agir
  ${AnsiColors.brightGreen}ai --auto <goal>${AnsiColors.reset}  Executa pipeline autônomo de ponta a ponta
  ${AnsiColors.brightGreen}mode <fast|plan|auto>${AnsiColors.reset} Alterna o modo de execução padrão do Shell
  ${AnsiColors.brightGreen}tier <fast|deep>${AnsiColors.reset}      Alterna entre modelo rápido e raciocínio profundo
  ${AnsiColors.brightGreen}clean${AnsiColors.reset}             Limpa os projetos / microfrontends do workspace
  ${AnsiColors.brightGreen}login${AnsiColors.reset}             Autentica na Shepherd Platform e vincula o projeto
  ${AnsiColors.brightGreen}changelog${AnsiColors.reset}         Gera ou atualiza o CHANGELOG.md automaticamente
  ${AnsiColors.brightGreen}flow${AnsiColors.reset}              Executa o fluxo de release TBD (bump + changelog + tag)
  ${AnsiColors.brightGreen}deploy${AnsiColors.reset}            Gerencia deploys e releases
  ${AnsiColors.brightGreen}test${AnsiColors.reset}              Gera ou executa testes
  ${AnsiColors.brightGreen}status / whoami${AnsiColors.reset}   Exibe informações do projeto atual, usuário e IA
  ${AnsiColors.brightGreen}clear / cls${AnsiColors.reset}       Limpa a tela do terminal
  ${AnsiColors.brightGreen}menu${AnsiColors.reset}              Abre o menu interativo numérico tradicional
  ${AnsiColors.brightGreen}exit / quit${AnsiColors.reset}       Sai do Shepherd Shell
''');
  }

  static void _clearScreen() {
    if (Platform.isWindows) {
      stdout.write('\x1B[2J\x1B[0f');
    } else {
      stdout.write('\x1B[2J\x1B[3J\x1B[H');
    }
  }

  static int _visibleLength(String str) {
    // Strip ANSI codes to calculate padding accurately
    final clean = str.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
    return clean.length;
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
