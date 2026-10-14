import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shepherd/src/i18n/i18n.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';
import '../../data/models/shell_session_model.dart';
import '../../domain/services/workspace_manifest_service.dart';
import '../../domain/services/workspace_scaffold_service.dart';
import 'shepherd_runner.dart';
import 'shepherd_shell_views.dart';
import 'workspace_gate.dart';
import '../../domain/services/ai_model_catalog_service.dart';

/// Interactive Shell (REPL) for Shepherd CLI.
/// Provides a continuous interactive environment where developers can run commands,
/// manage sessions, and talk to Shepherd AI without exiting to the system shell.
class ShepherdShell {
  static String activeMode = 'fast';
  static String activeTier = 'fast';
  static String activeProfile = 'medium';
  static String? _previousDir;

  static Future<void> start() async {
    if (WorkspaceManifest.tryLoad() == null) {
      if (stdin.hasTerminal && stdout.hasTerminal) {
        final go = await WorkspaceGate(
          login: () => executeShepherdCommand(['login'], inShell: true),
          init: () => executeShepherdCommand(['init'], inShell: true),
        ).run();
        if (!go) return;
      } else {
        print(t('gate.hint'));
      }
    }
    // Complete the standard YAML files of a workspace that exists
    if (WorkspaceManifest.tryLoad() != null) {
      WorkspaceScaffoldService.ensureShepherdFiles();
    }

    var session = ShellSessionModel.loadFromWorkspace();

    ShellViews.banner(session,
        mode: activeMode, tier: activeTier, profile: activeProfile);

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

      final rawCommand = args.first.toLowerCase();
      final command =
          rawCommand.startsWith('/') ? rawCommand.substring(1) : rawCommand;

      // Built-in Shell commands
      if (command == 'exit' ||
          command == 'quit' ||
          command == 'sair' ||
          command == 'salir' ||
          command == 'q') {
        print(t('shell.bye'));
        break;
      }

      if (command == 'clear' || command == 'cls') {
        _clearScreen();
        ShellViews.banner(session,
            mode: activeMode,
            tier: activeTier,
            profile: activeProfile,
            compact: true);
        continue;
      }

      if (command == 'status' || command == 'whoami' || command == 'session') {
        session = ShellSessionModel.loadFromWorkspace();
        ShellViews.status(session, tier: activeTier, mode: activeMode);
        continue;
      }

      if (command == 'advanced' ||
          command == 'avancado' ||
          command == 'avanzado') {
        activeProfile = 'advanced';
        activeTier = 'deep';
        print(
            '${AnsiColors.brightGreen}${t('shell.profile_adv')}${AnsiColors.reset}');
        continue;
      }

      if (command == 'medium' || command == 'medio') {
        activeProfile = 'medium';
        activeTier = 'fast';
        print(
            '${AnsiColors.brightGreen}${t('shell.profile_med')}${AnsiColors.reset}');
        continue;
      }

      if (command == 'local') {
        activeProfile = 'local';
        print(
            '${AnsiColors.brightGreen}${t('shell.profile_loc')}${AnsiColors.reset}');
        continue;
      }

      if (command == 'model' ||
          command == 'modelo' ||
          command == 'change-model') {
        if (args.length > 1) {
          final subArgs = ['ai', 'model', ...args.sublist(1)];
          await executeShepherdCommand(subArgs, inShell: true);
        } else {
          await executeShepherdCommand(['ai', 'model'], inShell: true);
        }
        session = ShellSessionModel.loadFromWorkspace();
        continue;
      }

      if (command == 'engine') {
        session = ShellSessionModel.loadFromWorkspace();
        final model = activeTier == 'deep'
            ? 'gemini-2.5-pro'
            : (session.aiModel ?? AiModelCatalogService.defaultGeminiModel);
        final provider = session.aiProvider ?? 'Shepherd Platform';
        print(
            '\n${AnsiColors.bold}${AnsiColors.brightCyan}${t('shell.engine_title')}${AnsiColors.reset}');
        print(
            '${t('shell.engine_provider')}${AnsiColors.bold}$provider${AnsiColors.reset}');
        print(
            '${t('shell.engine_model')}${AnsiColors.brightGreen}$model${AnsiColors.reset}');
        print(
            '${t('shell.engine_profile')}${AnsiColors.brightCyan}$activeProfile${AnsiColors.reset} ${t('shell.engine_profile_hint')}');
        print(
            '  Tier:     ${AnsiColors.brightYellow}$activeTier${AnsiColors.reset} ${t('shell.engine_tier_hint')}');
        print(
            '${t('shell.engine_mode')}${AnsiColors.brightCyan}$activeMode${AnsiColors.reset} ${t('shell.engine_mode_hint')}\n');
        continue;
      }

      if (command == 'mode') {
        if (args.length > 1) {
          final target = args[1].toLowerCase();
          if (['fast', 'plan', 'auto'].contains(target)) {
            activeMode = target;
            print(t('shell.mode_changed', {
              'mode': '${AnsiColors.brightCyan}$activeMode${AnsiColors.reset}'
            }));
          } else {
            print(t('shell.mode_valid'));
          }
        } else {
          print(t('shell.mode_current', {
            'mode': '${AnsiColors.brightCyan}$activeMode${AnsiColors.reset}'
          }));
        }
        continue;
      }

      if (command == 'tier') {
        if (args.length > 1) {
          final target = args[1].toLowerCase();
          if (['fast', 'deep'].contains(target)) {
            activeTier = target;
            print(t('shell.tier_changed', {
              'tier': '${AnsiColors.brightCyan}$activeTier${AnsiColors.reset}'
            }));
          } else {
            print(t('shell.tier_valid'));
          }
        } else {
          print(t('shell.tier_current', {
            'tier': '${AnsiColors.brightCyan}$activeTier${AnsiColors.reset}'
          }));
        }
        continue;
      }

      if (command == 'help' ||
          command == 'ajuda' ||
          command == 'ayuda' ||
          command == '?') {
        ShellViews.help();
        continue;
      }

      if (command == 'pwd') {
        print(
            '📂 ${AnsiColors.brightCyan}${Directory.current.path}${AnsiColors.reset}');
        continue;
      }

      if (command == 'workspace' || command == 'ws') {
        final manifest = WorkspaceManifest.tryLoad();
        if (manifest != null) {
          print(
              '\n🏢 ${AnsiColors.bold}${AnsiColors.brightYellow}Workspace: ${manifest.name}${AnsiColors.reset} (v${manifest.version})');
          print(t('shell.ws_root', {'path': manifest.rootDir.path}));
          print(t('shell.ws_projects', {'n': manifest.projects.length}));
          for (final proj in manifest.projects) {
            final projFullPath =
                p.normalize(p.join(manifest.rootDir.path, proj.path));
            final isCurrent = Directory.current.path == projFullPath ||
                Directory.current.path.startsWith('$projFullPath/');
            final marker = isCurrent ? ' 👉 ${AnsiColors.brightGreen}' : '    ';
            print(
                '$marker${proj.name} [${proj.category}] (${proj.path})${AnsiColors.reset}');
          }
          print(t('shell.ws_tip', {
            'cmd':
                '${AnsiColors.brightCyan}cd <project_name>${AnsiColors.reset}'
          }));
        } else {
          print(t('shell.ws_none'));
        }
        continue;
      }

      if (command == 'cd') {
        String? targetPath;
        if (args.length > 1) {
          targetPath = args.sublist(1).join(' ').trim();
        }

        final home = Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ??
            '';

        if (targetPath == null || targetPath.isEmpty || targetPath == '~') {
          targetPath = home;
        } else if (targetPath == '-') {
          targetPath = _previousDir ?? home;
        } else if (targetPath.startsWith('~')) {
          targetPath = targetPath.replaceFirst('~', home);
        }

        var targetDir = Directory(
            p.normalize(p.absolute(Directory.current.path, targetPath)));

        // If direct directory does not exist, check if it is a project registered in WorkspaceManifest
        if (!targetDir.existsSync()) {
          final manifest = WorkspaceManifest.tryLoad();
          if (manifest != null) {
            if (targetPath.toLowerCase() == 'workspace' ||
                targetPath.toLowerCase() == 'ws' ||
                targetPath.toLowerCase() == 'root') {
              targetDir = manifest.rootDir;
            } else {
              final match = manifest.projects.where((proj) =>
                  proj.name.toLowerCase() == targetPath!.toLowerCase() ||
                  proj.id.toLowerCase() == targetPath.toLowerCase());
              if (match.isNotEmpty) {
                targetDir = Directory(p.normalize(
                    p.join(manifest.rootDir.path, match.first.path)));
              }
            }
          }
        }

        if (targetDir.existsSync()) {
          _previousDir = Directory.current.path;
          Directory.current = targetDir.absolute.path;
          session = ShellSessionModel.loadFromWorkspace();
          print(
              '📂 ${AnsiColors.brightGreen}${t('shell.cd_changed')}${AnsiColors.reset} ${Directory.current.path}');
          if (session.workspaceName != null &&
              session.workspaceName != session.projectName) {
            print(
                '🏢 ${AnsiColors.brightYellow}${t('shell.cd_workspace')}${AnsiColors.reset} ${session.workspaceName} | 📦 ${AnsiColors.brightCyan}${t('shell.cd_project')}${AnsiColors.reset} ${session.projectName}');
          } else if (session.projectName.isNotEmpty) {
            print(
                '📦 ${AnsiColors.brightCyan}${t('shell.cd_active')}${AnsiColors.reset} ${session.projectName}');
          }
        } else {
          print(
              '${AnsiColors.brightRed}${t('shell.cd_missing')}${AnsiColors.reset} $targetPath');
        }
        continue;
      }

      const knownCommands = {
        'ai',
        'clean',
        'changelog',
        'flow',
        'deploy',
        'test',
        'login',
        'init',
        'pull',
        'sync',
        'format',
        'analyze',
        'status',
        'whoami',
        'session',
        'mode',
        'tier',
        'model',
        'engine',
        'mcp',
        'menu',
        'help',
        '?',
        'clear',
        'cls',
        'exit',
        'quit',
        'linter',
        'azurecli',
        'version',
        'about',
        'tag',
        'recover',
        'advanced',
        'avancado',
        'avanzado',
        'medium',
        'medio',
        'local',
        'ajuda',
        'ayuda',
        'cd',
        'pwd',
        'workspace',
        'ws',
        'lang',
      };

      List<String> effectiveArgs = [command, ...args.sublist(1)];
      if (!knownCommands.contains(command)) {
        // Natural language query or @file mention: automatically route to ai
        effectiveArgs = [
          'ai',
          trimmed,
          '--mode',
          activeMode,
          '--tier',
          activeTier,
          '--profile',
          activeProfile
        ];
      } else if (command == 'ai' &&
          args.length > 1 &&
          !args.contains('--mode') &&
          !args.contains('--plan') &&
          !args.contains('--auto')) {
        effectiveArgs = [
          ...effectiveArgs,
          '--mode',
          activeMode,
          '--tier',
          activeTier,
          '--profile',
          activeProfile
        ];
      }

      // Execute Shepherd command
      try {
        await executeShepherdCommand(effectiveArgs, inShell: true);

        // If command was login, pull, or ai config, refresh the session state immediately
        if (command == 'login' ||
            command == 'init' ||
            command == 'pull' ||
            command == 'ai') {
          session = ShellSessionModel.loadFromWorkspace();
        }
      } catch (e, stack) {
        print(
            '\n${AnsiColors.brightRed}${t('shell.cmd_error')}${AnsiColors.reset} $e');
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
    if (displayWorkspace.isNotEmpty) {
      buffer.write(
          '${AnsiColors.brightBlack}[${AnsiColors.brightYellow}$displayWorkspace${AnsiColors.brightBlack}]${AnsiColors.reset}');
    }

    buffer
        .write(' ${AnsiColors.brightMagenta}($activeMode)${AnsiColors.reset}');

    if (session.userName != null && session.userName!.isNotEmpty) {
      buffer.write(
          ' ${AnsiColors.brightGreen}(${session.userName})${AnsiColors.reset}');
    }

    buffer.write(' ${AnsiColors.brightCyan}>${AnsiColors.reset} ');
    return buffer.toString();
  }

  static void _clearScreen() {
    if (Platform.isWindows) {
      stdout.write('\x1B[2J\x1B[0f');
    } else {
      stdout.write('\x1B[2J\x1B[3J\x1B[H');
    }
  }

  /// Parses a command line string into a list of argument tokens,
  /// preserving quoted segments (e.g. `ai "my prompt with spaces"`).
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
