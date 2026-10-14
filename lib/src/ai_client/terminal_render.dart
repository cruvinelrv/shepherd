import 'dart:io';

import '../i18n/i18n.dart';
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

/// A terminal command the engine proposed. The engine never runs it: the chat asks
/// the user and runs it.
class CommandProposal {
  final String id;
  final String command;
  final String cwd;
  final bool risky;

  /// The first command comes before the first file in the answer.
  final bool before;
  const CommandProposal(this.id, this.command, this.cwd,
      {this.risky = false, this.before = false});
}

/// Shows what the engine reports while it works. It decides nothing: the engine
/// says what happened and this only tells the user.
class TurnRenderer {
  /// [out] is where everything is written (stdout; a buffer in tests). The model's
  /// reasoning and the progress line are only shown on a terminal ([tty]): a
  /// redirected output carries just the answer.
  TurnRenderer({StringSink? out, bool? tty})
      : out = out ?? stdout,
        _tty = tty ?? stdout.hasTerminal;

  final StringSink out;
  final bool _tty;
  final List<Proposal> proposals = [];
  final List<CommandProposal> commands = [];
  int? _requestId;
  bool _lineOpen = false;
  // A progress line ("waiting for the model") that is rewritten in place and
  // erased as soon as something else is printed. Only on a terminal.
  bool _statusShown = false;
  bool _reasoningOpen = false;

  /// Only events of this turn (or of no turn) are shown.
  void startTurn(int requestId) {
    _requestId = requestId;
    proposals.clear();
    commands.clear();
  }

  void _clearStatus() {
    if (_statusShown) out.write('\r\x1B[K');
    _statusShown = false;
  }

  /// Ends the gray reasoning block before anything else is written.
  void _closeReasoning() {
    if (!_reasoningOpen) return;
    out.writeln(AnsiColors.reset);
    _reasoningOpen = false;
  }

  void _line(String text) {
    _closeReasoning();
    _clearStatus();
    if (_lineOpen) out.writeln();
    _lineOpen = false;
    out.writeln(text);
  }

  void handle(RpcNotification n) {
    final p = n.params;
    final rid = p['requestId'];
    if (rid is int && _requestId != null && rid != _requestId) return;
    switch (n.method) {
      case 'session/textDelta':
        final text = p['text'] as String? ?? '';
        _closeReasoning();
        _clearStatus();
        out.write(text);
        _lineOpen = text.isNotEmpty && !text.endsWith('\n');
      case 'session/reasoningDelta':
        if (!_tty) return;
        _clearStatus();
        if (!_reasoningOpen) {
          out.write('${AnsiColors.gray}💭 ');
          _reasoningOpen = true;
        }
        out.write(p['text'] as String? ?? '');
      case 'session/status':
        final phase = p['phase'];
        final secs = p['idleSeconds'];
        final what = t(switch (phase) {
          'indexing' => 'render.phase_indexing',
          'searching' => 'render.phase_searching',
          'writing' => 'render.phase_writing',
          'thinking' => 'render.phase_thinking',
          _ => 'render.phase_waiting',
        });
        if (_tty && !_lineOpen) {
          out.write(
              '\r\x1B[K${AnsiColors.gray}⏳ $what... (${secs}s)${AnsiColors.reset}');
          _statusShown = true;
        }
      case 'session/contextTrimmed':
        _line('${AnsiColors.gray}${t('render.trimmed', {
              'n': p['droppedMessages']
            })}${AnsiColors.reset}');
      case 'session/formatWarning':
        _line('${AnsiColors.yellow}⚠️  ${p['message']}${AnsiColors.reset}');
      case 'files/started':
        _line('${AnsiColors.gray}${t('render.preparing', {
              'path': p['path']
            })}${AnsiColors.reset}');
      case 'files/proposal':
        proposals.add(Proposal('${p['proposalId']}', '${p['path']}',
            '${p['content']}', p['isNew'] == true));
      case 'commands/proposal':
        commands.add(CommandProposal(
            '${p['proposalId']}', '${p['command']}', '${p['cwd']}',
            risky: p['risky'] == true, before: p['before'] == true));
      case 'files/result':
        final ok = p['applied'] == true;
        _line(ok
            ? '${AnsiColors.brightGreen}${t('render.written', {
                    'path': p['path']
                  })}${AnsiColors.reset}'
            : '${AnsiColors.brightRed}${t('render.write_failed', {
                    'path': p['path']
                  })}${AnsiColors.reset}');
        proposals.removeWhere((x) => x.id == '${p['proposalId']}');
      case 'files/blocked':
        _line('${AnsiColors.yellow}${t('render.blocked', {
              'path': p['path'],
              'reason': p['reason']
            })}${AnsiColors.reset}');
      case 'rag/progress':
        if (p['phase'] == 'done') {
          _line('${AnsiColors.gray}${t('render.indexed', {
                'project': p['project'],
                'n': p['indexedFiles']
              })}${AnsiColors.reset}');
        }
      case 'rag/done':
        final warnings = (p['warnings'] as List?)?.cast<String>() ?? const [];
        for (final w in warnings) {
          _line('${AnsiColors.yellow}⚠️  $w${AnsiColors.reset}');
        }
        final pruned = (p['pruned'] as List?)?.length ?? 0;
        final backend =
            '${p['source']}${p['model'] != null && '${p['model']}'.isNotEmpty ? ': ${p['model']}' : ''}';
        _line('${AnsiColors.gray}${t('render.context_ready', {
              'backend': backend
            })}${pruned > 0 ? t('render.pruned', {
                'n': pruned
              }) : ''}${AnsiColors.reset}');
      case 'rag/context':
        _line('${AnsiColors.gray}${t('render.context_chunks', {
              'n': p['chunks']
            })}${AnsiColors.reset}');
      case 'rag/unavailable':
        _line('${AnsiColors.yellow}${t('render.rag_unavailable', {
              'message': p['message']
            })}${AnsiColors.reset}');
    }
  }

  /// Ends the line the answer left open.
  void endTurn() {
    _closeReasoning();
    _clearStatus();
    if (_lineOpen) out.writeln();
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
        'offline_expired' =>
          e.message, // the engine words it in the user's language
        'session_expired' => t('err.session_expired'),
        _ => t('err.login_required'),
      };
    case 'not_configured':
      return t('err.not_configured', {'detail': e.message});
    case 'ollama_offline':
      return t('err.ollama_offline');
    case 'invalid_key':
      return t('err.invalid_key');
    case 'model_unavailable':
      return t('err.model_unavailable', {'model': e.data['model'] ?? ''});
    case 'rate_limited':
      return t('err.rate_limited');
    case 'busy':
      return t('err.busy');
    default:
      return e.message;
  }
}
