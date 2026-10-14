import 'dart:convert';
import 'package:shepherd/src/utils/ansi_colors.dart';
import '../../../i18n/i18n.dart';
import '../../domain/services/mcp_client_service.dart';

/// Handler for `shepherd mcp` command and Shell REPL `mcp` commands.
class McpCommand {
  static Future<void> execute(List<String> args) async {
    final sub = args.isNotEmpty ? args.first.toLowerCase() : 'list';

    switch (sub) {
      case 'list':
        await _handleList();
        break;
      case 'status':
        await _handleStatus();
        break;
      case 'call':
        await _handleCall(args.skip(1).toList());
        break;
      case 'help':
      default:
        _printHelp();
        break;
    }
  }

  static Future<void> _handleList() async {
    final configs = McpClientService.loadConfigs();
    if (configs.isEmpty) {
      print(
          '\n${AnsiColors.brightYellow}${t('mcp.none_global')}${AnsiColors.reset}');
      print(t('mcp.edit', {
        'file': '${AnsiColors.brightCyan}.shepherd/mcp.json${AnsiColors.reset}'
      }));
      print(t('mcp.example'));
      print('''{
  "mcpServers": {
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git", "."]
    }
  }
}''');
      return;
    }

    print('\n${AnsiColors.bold}${AnsiColors.brightCyan}${t('mcp.configured', {
          'n': configs.length
        })}${AnsiColors.reset}');
    for (final cfg in configs) {
      print(
          '\n  ${AnsiColors.bold}• ${cfg.name}${AnsiColors.reset} [${t('mcp.command_label')}: ${cfg.command} ${cfg.args.join(' ')}]');
      stdoutWrite(t('mcp.connecting'));
      final stopwatch = Stopwatch()..start();
      try {
        final tools = await McpClientService.listToolsForServer(cfg);
        stopwatch.stop();
        print(
            '${AnsiColors.brightGreen}OK${AnsiColors.reset} ${t('mcp.ok_tools', {
              'ms': stopwatch.elapsedMilliseconds,
              'n': tools.length
            })}');
        for (final tool in tools) {
          final desc = tool.description != null ? ' - ${tool.description}' : '';
          print(
              '      ⚡ ${AnsiColors.brightYellow}${tool.name}${AnsiColors.reset}$desc');
        }
      } catch (e) {
        stopwatch.stop();
        print(
            '${AnsiColors.brightRed}${t('mcp.failed')}${AnsiColors.reset} ($e)');
      }
    }
    print('');
  }

  static Future<void> _handleStatus() async {
    final configs = McpClientService.loadConfigs();
    if (configs.isEmpty) {
      print(
          '\n${AnsiColors.brightYellow}${t('mcp.none_file')}${AnsiColors.reset}\n');
      return;
    }

    print(
        '\n${AnsiColors.bold}${AnsiColors.brightCyan}${t('mcp.check_title')}${AnsiColors.reset}');
    for (final cfg in configs) {
      stdoutWrite(t('mcp.handshake', {'name': cfg.name}));
      final sw = Stopwatch()..start();
      try {
        final tools = await McpClientService.listToolsForServer(cfg);
        sw.stop();
        print(
            '${AnsiColors.brightGreen}ONLINE${AnsiColors.reset} ${t('mcp.online', {
              'ms': sw.elapsedMilliseconds,
              'n': tools.length
            })}');
      } catch (e) {
        sw.stop();
        print(
            '${AnsiColors.brightRed}${t('mcp.offline')}${AnsiColors.reset} ($e)');
      }
    }
    print('');
  }

  static Future<void> _handleCall(List<String> args) async {
    if (args.length < 2) {
      print(
          '${AnsiColors.brightRed}${t('mcp.usage')}${AnsiColors.reset} ${t('mcp.usage_call')}');
      print(t('mcp.example_call'));
      return;
    }

    final serverName = args[0];
    final toolName = args[1];
    Map<String, dynamic> toolArgs = {};

    if (args.length > 2) {
      try {
        final rawJson = args.sublist(2).join(' ');
        final parsed = jsonDecode(rawJson);
        if (parsed is Map) {
          toolArgs = Map<String, dynamic>.from(parsed);
        }
      } catch (e) {
        print(
            '${AnsiColors.brightRed}${t('mcp.bad_json')}${AnsiColors.reset} $e');
        return;
      }
    }

    final configs = McpClientService.loadConfigs();
    final config = configs
        .where((c) => c.name.toLowerCase() == serverName.toLowerCase())
        .firstOrNull;

    if (config == null) {
      print('${AnsiColors.brightRed}${t('mcp.not_found', {
            'name': serverName
          })}${AnsiColors.reset}');
      return;
    }

    print(
        '${t('mcp.running')} ${AnsiColors.brightCyan}$serverName::$toolName${AnsiColors.reset}...');
    final result = await McpClientService.callTool(config, toolName, toolArgs);
    print('\n${AnsiColors.bold}${t('mcp.result')}${AnsiColors.reset}');
    print(result);
    print('');
  }

  static void _printHelp() {
    final g = AnsiColors.brightGreen, x = AnsiColors.reset;
    print('''
${AnsiColors.bold}${AnsiColors.brightCyan}${t('mcp.help_title')}$x

  ${g}shepherd mcp$x ${t('mcp.help_list')} ${g}mcp list$x        ${t('mcp.help_list_desc')}
  ${g}shepherd mcp status$x               ${t('mcp.help_status_desc')}
  ${g}shepherd mcp call <srv> <tool> [args]$x ${t('mcp.help_call_desc')}
''');
  }

  static void stdoutWrite(String msg) {
    // helper wrapper
    print(msg);
  }
}
