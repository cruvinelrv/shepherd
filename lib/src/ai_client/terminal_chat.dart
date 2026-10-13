import 'dart:async';
import 'dart:io';

import '../tools/domain/services/ai_config_service.dart';
import '../tools/presentation/commands/model_switch/model_options.dart';
import '../tools/presentation/commands/model_switch/model_switch_command.dart';
import '../utils/ansi_colors.dart';
import 'diff_view.dart';
import 'engine_session.dart';
import 'rpc_client.dart';
import 'terminal_render.dart';

/// The conversation in the terminal: a thin client. Everything that matters
/// (the model, the retrieval, the files) is the engine's; this reads what the
/// user types, shows what the engine says and asks before a file is written.
class TerminalChat {
  final EngineSession session;
  final TurnRenderer _renderer = TurnRenderer();
  late final StreamSubscription<RpcNotification> _events;

  TerminalChat(this.session) {
    _events = session.client.notifications.listen(_renderer.handle);
  }

  Future<void> close() async {
    await _events.cancel();
    await session.close();
  }

  void printHeader() {
    final where = session.projects.isEmpty
        ? 'workspace inteiro'
        : session.projects.join(', ');
    print(
        '\n${AnsiColors.bold}🤖 Shepherd AI${AnsiColors.reset} — ${AnsiColors.brightCyan}${session.model}${AnsiColors.reset} (${providerDisplayName(session.provider)}) | modo ${session.mode} | $where');
    if (session.offline) {
      print(
          '${AnsiColors.yellow}⚠️  Sem conexão com o Shepherd Union: usando a última validação do seu login.${AnsiColors.reset}');
    }
    print(
        'Comandos: /plan /auto /fast · /model · /projects a,b · /help · "sair"\n');
  }

  /// The prompt loop, until the user leaves or the input ends.
  Future<void> interactive() async {
    printHeader();
    while (true) {
      await Future<void>.delayed(
          Duration.zero); // let pending engine messages print first
      stdout.write('${AnsiColors.bold}[${session.mode}]${AnsiColors.reset} > ');
      final line = stdin.readLineSync()?.trim();
      if (line == null) break;
      if (line.isEmpty) continue;
      if (const {'sair', 'exit', 'quit', ':q'}.contains(line.toLowerCase()))
        break;
      if (line.startsWith('/')) {
        final ask = await _command(line);
        if (ask == null) continue;
        await this.ask(ask);
      } else {
        await ask(line);
      }
    }
    print('\nAté mais!');
  }

  /// Sends one question and shows the answer. Returns false when it failed.
  Future<bool> ask(String text, {bool canPrompt = true}) async {
    int? turn;
    final sigint = ProcessSignal.sigint.watch().listen((_) {
      if (turn != null) session.client.cancel(turn!);
    });
    final began = DateTime.now();
    try {
      final r =
          await session.client.request('session/send', {'text': text}, (id) {
        turn = id;
        _renderer.startTurn(id);
      });
      _renderer.endTurn();
      if (r['stopReason'] == 'cancelled')
        print('${AnsiColors.gray}⏹ interrompido${AnsiColors.reset}');
      _footer(r, DateTime.now().difference(began));
      await _confirmProposals(canPrompt);
      return true;
    } on RpcException catch (e) {
      _renderer.endTurn();
      stderr.writeln('\n❌ ${describeRpcError(e)}\n');
      return false;
    } finally {
      await sigint.cancel();
    }
  }

  void _footer(Map<String, dynamic> result, Duration took) {
    final u = (result['usage'] as Map?)?.cast<String, dynamic>() ?? const {};
    final local = u['isLocal'] == true;
    print(
        '${AnsiColors.gray}🧠 ${session.model} · ${providerDisplayName(session.provider)} · modo ${session.mode} · ${took.inMilliseconds} ms · ${u['promptTokens']}+${u['completionTokens']} tokens (${local ? 'Local / Gratuito' : 'Nuvem'})${AnsiColors.reset}');
  }

  /// In fast mode the engine waits for a yes before it writes a file.
  Future<void> _confirmProposals(bool canPrompt) async {
    final pending = List<Proposal>.of(_renderer.proposals);
    _renderer.proposals.clear();
    if (pending.isEmpty) return;
    if (!canPrompt || !stdin.hasTerminal) {
      print(
          '${AnsiColors.yellow}⚠️  ${pending.length} arquivo(s) proposto(s) e não gravado(s): use --auto para gravar sem perguntar.${AnsiColors.reset}');
      return;
    }
    for (final p in pending) {
      print(
          '\n${AnsiColors.bold}📝 Alteração proposta pela IA:${AnsiColors.reset}');
      final f = File(p.path);
      print(renderDiff(
          path: p.path,
          original: p.isNew || !f.existsSync() ? null : f.readAsStringSync(),
          content: p.content));
      stdout.write(
          'Aplicar em ${AnsiColors.brightCyan}${p.path}${AnsiColors.reset}? [S/n]: ');
      final a = stdin.readLineSync()?.trim().toLowerCase();
      final yes =
          a == null || a.isEmpty || const {'s', 'sim', 'y', 'yes'}.contains(a);
      try {
        final r = await session.client
            .request('session/confirm', {'proposalId': p.id, 'approved': yes});
        print(yes
            ? (r['applied'] == true
                ? '✅ ${AnsiColors.brightGreen}${p.path}${AnsiColors.reset} gravado\n'
                : '❌ não foi possível gravar ${p.path}\n')
            : '⏭️  ${p.path} ignorado\n');
      } on RpcException catch (e) {
        stderr.writeln('❌ ${describeRpcError(e)}');
      }
    }
  }

  /// Handles a `/command`. Returns text to ask afterwards, or null.
  Future<String?> _command(String line) async {
    final parts = line.split(RegExp(r'\s+'));
    final cmd = parts.first.toLowerCase();
    final rest = parts.skip(1).join(' ').trim();
    try {
      switch (cmd) {
        case '/plan' || '/plano' || '/auto' || '/fast':
          await session
              .setMode(cmd.replaceAll('/', '').replaceAll('plano', 'plan'));
          print('✅ Modo ${session.mode}');
          return rest.isEmpty ? null : rest;
        case '/mode' || '/modo':
          if (const {'fast', 'plan', 'auto'}.contains(rest)) {
            await session.setMode(rest);
            print('✅ Modo ${session.mode}');
          } else {
            print('Modo atual: ${session.mode}. Use /mode fast|plan|auto.');
          }
        case '/model' || '/modelo' || '/trocar-modelo':
          await _switchModel(rest);
        case '/projects' || '/projetos':
          await session.setProjects(rest.isEmpty
              ? []
              : rest
                  .split(RegExp(r'[,\s]+'))
                  .where((s) => s.isNotEmpty)
                  .toList());
          print(
              '✅ Escopo: ${session.projects.isEmpty ? 'workspace inteiro' : session.projects.join(', ')}');
        case '/rag':
          print(
              'O RAG é definido ao iniciar: use --rag ou --no-rag em `shepherd ai`.');
        case '/help' || '/ajuda' || '/?':
          _help();
        default:
          print('Comando desconhecido. Digite /help.');
      }
    } on RpcException catch (e) {
      stderr.writeln('❌ ${describeRpcError(e)}');
    }
    return null;
  }

  Future<void> _switchModel(String arg) async {
    final config = AiConfigService().load();
    final choice = await chooseModel(
        aiConfig: config,
        arg: arg,
        activeProvider: session.provider,
        activeModel: session.model);
    if (choice.cancelled) {
      print('ℹ️  Troca cancelada. Mantido: ${session.model}.');
      return;
    }
    final selected = choice.selected;
    if (selected == null) {
      print(
          '❌ Opção ou modelo não reconhecido. Digite "/model" para ver a lista.');
      return;
    }
    saveModelChoice(
        config, selected); // the engine reads the file again on setModel
    await session.setModel(selected.provider, selected.model);
    print(
        '${AnsiColors.brightGreen}✅ Modelo alterado para: ${session.model} (${providerDisplayName(session.provider)})${AnsiColors.reset}');
  }

  void _help() {
    print('''
  /plan | /auto | /fast       muda o modo (com texto depois, já pergunta)
  /model [nome]               troca o modelo ou o provedor
  /projects a,b               limita o contexto e os arquivos a estes projetos
  sair                        encerra
Ctrl+C durante uma resposta interrompe só a resposta.''');
  }
}
