import 'dart:io';

import '../utils/ansi_colors.dart';
import 'rpc_client.dart';

/// A file the engine proposed and is waiting to have confirmed.
class Proposal {
  final String id;
  final String path;
  final String content;
  final bool isNew;
  const Proposal(this.id, this.path, this.content, this.isNew);
}

/// Shows what the engine reports while it works. It decides nothing: the engine
/// says what happened and this only tells the user.
class TurnRenderer {
  final List<Proposal> proposals = [];
  int? _requestId;
  bool _lineOpen = false;
  // A progress line ("waiting for the model") that is rewritten in place and
  // erased as soon as something else is printed. Only on a terminal.
  bool _statusShown = false;

  /// Only events of this turn (or of no turn) are shown.
  void startTurn(int requestId) {
    _requestId = requestId;
    proposals.clear();
  }

  void _clearStatus() {
    if (_statusShown) stdout.write('\r\x1B[K');
    _statusShown = false;
  }

  void _line(String text) {
    _clearStatus();
    if (_lineOpen) stdout.writeln();
    _lineOpen = false;
    stdout.writeln(text);
  }

  void handle(RpcNotification n) {
    final p = n.params;
    final rid = p['requestId'];
    if (rid is int && _requestId != null && rid != _requestId) return;
    switch (n.method) {
      case 'session/textDelta':
        final text = p['text'] as String? ?? '';
        _clearStatus();
        stdout.write(text);
        _lineOpen = text.isNotEmpty && !text.endsWith('\n');
      case 'session/status':
        final phase = p['phase'];
        final secs = p['idleSeconds'];
        final what = switch (phase) {
          'indexing' => 'indexando o workspace',
          'searching' => 'buscando contexto',
          'writing' => 'escrevendo',
          'thinking' => 'pensando',
          _ => 'aguardando o modelo',
        };
        if (stdout.hasTerminal && !_lineOpen) {
          stdout.write(
              '\r\x1B[K${AnsiColors.gray}⏳ $what... (${secs}s)${AnsiColors.reset}');
          _statusShown = true;
        }
      case 'session/formatWarning':
        _line('${AnsiColors.yellow}⚠️  ${p['message']}${AnsiColors.reset}');
      case 'files/started':
        _line(
            '${AnsiColors.gray}📄 preparando ${p['path']}...${AnsiColors.reset}');
      case 'files/proposal':
        proposals.add(Proposal('${p['proposalId']}', '${p['path']}',
            '${p['content']}', p['isNew'] == true));
      case 'files/result':
        final ok = p['applied'] == true;
        _line(ok
            ? '${AnsiColors.brightGreen}✅ ${p['path']} gravado${AnsiColors.reset}'
            : '${AnsiColors.brightRed}❌ não foi possível gravar ${p['path']}${AnsiColors.reset}');
        proposals.removeWhere((x) => x.id == '${p['proposalId']}');
      case 'files/blocked':
        _line(
            '${AnsiColors.yellow}🚫 ${p['path']} não foi proposto: ${p['reason']}${AnsiColors.reset}');
      case 'rag/progress':
        if (p['phase'] == 'done') {
          _line(
              '${AnsiColors.gray}🧠 ${p['project']}: ${p['indexedFiles']} arquivo(s) no índice${AnsiColors.reset}');
        }
      case 'rag/done':
        final warnings = (p['warnings'] as List?)?.cast<String>() ?? const [];
        for (final w in warnings) {
          _line('${AnsiColors.yellow}⚠️  $w${AnsiColors.reset}');
        }
        final pruned = (p['pruned'] as List?)?.length ?? 0;
        _line(
            '${AnsiColors.gray}🧠 Contexto pronto (${p['source']}${p['model'] != null && '${p['model']}'.isNotEmpty ? ': ${p['model']}' : ''})${pruned > 0 ? ' · $pruned índice(s) antigo(s) removido(s)' : ''}${AnsiColors.reset}');
      case 'rag/context':
        _line(
            '${AnsiColors.gray}📎 ${p['chunks']} trecho(s) do workspace no contexto${AnsiColors.reset}');
      case 'rag/unavailable':
        _line(
            '${AnsiColors.yellow}⚠️  Contexto do workspace indisponível: ${p['message']}${AnsiColors.reset}');
    }
  }

  /// Ends the line the answer left open.
  void endTurn() {
    _clearStatus();
    if (_lineOpen) stdout.writeln();
    _lineOpen = false;
    _requestId = null;
  }
}

/// A sentence a person can act on, for an error the engine sent.
String describeRpcError(RpcException e) {
  final reason = e.data['reason'];
  switch (e.stableCode) {
    case 'not_authenticated':
      return switch (reason) {
        'offline_expired' => e.message,
        'session_expired' =>
          'Sua sessão expirou. Execute `shepherd login` e tente de novo.',
        _ => 'Faça login para usar o Shepherd AI: `shepherd login`.',
      };
    case 'not_configured':
      return 'Nenhum provedor de IA configurado. Execute `shepherd ai config`. (${e.message})';
    case 'ollama_offline':
      return 'O servidor do Ollama não respondeu. Abra o Ollama (ou ajuste o endereço com `shepherd ai config`).';
    case 'invalid_key':
      return 'O provedor recusou a chave de API. Atualize-a com `shepherd ai config`.';
    case 'model_unavailable':
      return 'O modelo ${e.data['model'] ?? ''} não está disponível para a sua conta. Escolha outro com /model (ou `shepherd ai model`).';
    case 'rate_limited':
      return 'Limite de uso do provedor atingido. Aguarde um pouco e tente de novo.';
    case 'busy':
      return 'O motor ainda está respondendo à pergunta anterior.';
    case 'engine_exited':
      return e.message;
    default:
      return e.message;
  }
}
