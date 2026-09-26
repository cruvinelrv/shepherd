import 'dart:convert';
import 'package:shepherd/src/utils/ansi_colors.dart';
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
      print('\n${AnsiColors.brightYellow}ℹ️  Nenhum servidor MCP configurado no workspace ou globalmente.${AnsiColors.reset}');
      print('Edite o arquivo ${AnsiColors.brightCyan}.shepherd/mcp.json${AnsiColors.reset} para adicionar servidores MCP.');
      print('Exemplo:');
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

    print('\n${AnsiColors.bold}${AnsiColors.brightCyan}🔌 Servidores MCP Configurados (${configs.length}):${AnsiColors.reset}');
    for (final cfg in configs) {
      print('\n  ${AnsiColors.bold}• ${cfg.name}${AnsiColors.reset} [comando: ${cfg.command} ${cfg.args.join(' ')}]');
      stdoutWrite('    Conectando e buscando ferramentas... ');
      final stopwatch = Stopwatch()..start();
      try {
        final tools = await McpClientService.listToolsForServer(cfg);
        stopwatch.stop();
        print('${AnsiColors.brightGreen}OK${AnsiColors.reset} (${stopwatch.elapsedMilliseconds}ms, ${tools.length} ferramentas)');
        for (final tool in tools) {
          final desc = tool.description != null ? ' - ${tool.description}' : '';
          print('      ⚡ ${AnsiColors.brightYellow}${tool.name}${AnsiColors.reset}$desc');
        }
      } catch (e) {
        stopwatch.stop();
        print('${AnsiColors.brightRed}FALHOU${AnsiColors.reset} ($e)');
      }
    }
    print('');
  }

  static Future<void> _handleStatus() async {
    final configs = McpClientService.loadConfigs();
    if (configs.isEmpty) {
      print('\n${AnsiColors.brightYellow}ℹ️  Nenhum servidor MCP configurado em .shepherd/mcp.json${AnsiColors.reset}\n');
      return;
    }

    print('\n${AnsiColors.bold}${AnsiColors.brightCyan}🔍 Verificação de Conectividade MCP:${AnsiColors.reset}');
    for (final cfg in configs) {
      stdoutWrite('  [${cfg.name}] Testando handshake JSON-RPC... ');
      final sw = Stopwatch()..start();
      try {
        final tools = await McpClientService.listToolsForServer(cfg);
        sw.stop();
        print('${AnsiColors.brightGreen}ONLINE${AnsiColors.reset} (${sw.elapsedMilliseconds}ms | ${tools.length} tools disponíveis)');
      } catch (e) {
        sw.stop();
        print('${AnsiColors.brightRed}OFFLINE / ERRO${AnsiColors.reset} ($e)');
      }
    }
    print('');
  }

  static Future<void> _handleCall(List<String> args) async {
    if (args.length < 2) {
      print('${AnsiColors.brightRed}Uso:${AnsiColors.reset} shepherd mcp call <servidor> <ferramenta> [argumentos_json]');
      print('Exemplo: shepherd mcp call git git_status "{}"');
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
        print('${AnsiColors.brightRed}❌ JSON inválido para argumentos:${AnsiColors.reset} $e');
        return;
      }
    }

    final configs = McpClientService.loadConfigs();
    final config = configs.where((c) => c.name.toLowerCase() == serverName.toLowerCase()).firstOrNull;

    if (config == null) {
      print('${AnsiColors.brightRed}❌ Servidor MCP "$serverName" não encontrado em .shepherd/mcp.json${AnsiColors.reset}');
      return;
    }

    print('⏳ Executando ${AnsiColors.brightCyan}$serverName::$toolName${AnsiColors.reset}...');
    final result = await McpClientService.callTool(config, toolName, toolArgs);
    print('\n${AnsiColors.bold}Resultado:${AnsiColors.reset}');
    print(result);
    print('');
  }

  static void _printHelp() {
    print('''
${AnsiColors.bold}${AnsiColors.brightCyan}Comandos MCP (Model Context Protocol):${AnsiColors.reset}

  ${AnsiColors.brightGreen}shepherd mcp${AnsiColors.reset} ou ${AnsiColors.brightGreen}mcp list${AnsiColors.reset}        Lista servidores e ferramentas ativas
  ${AnsiColors.brightGreen}shepherd mcp status${AnsiColors.reset}               Testa a conexão e latência de cada servidor
  ${AnsiColors.brightGreen}shepherd mcp call <srv> <tool> [args]${AnsiColors.reset} Executa uma ferramenta MCP diretamente
''');
  }

  static void stdoutWrite(String msg) {
    // helper wrapper
    print(msg);
  }
}
