import 'dart:io';

import 'package:shepherd/src/ai_client/rpc_client.dart';
import 'package:shepherd/src/ai_client/terminal_render.dart';
import 'package:shepherd/src/ai_client/usage_notice.dart';
import 'package:shepherd/src/i18n/i18n.dart';
import 'package:shepherd/src/ai_client/terminal_chat.dart';
import 'package:test/test.dart';

RpcNotification _n(String method, Map<String, dynamic> params) => RpcNotification(method, params);
String _plain(StringBuffer b) => b.toString().replaceAll(RegExp(r'\x1B\[[0-9;]*[mK]'), '');

void main() {
  hintTests();
  setUpAll(() => I18n.use(ShepherdLang.en));
  tearDownAll(I18n.reset);

  group('terminal: the model reasoning', () {
    test('is shown apart, in gray, and closed before the answer starts', () {
      final out = StringBuffer();
      final r = TurnRenderer(out: out, tty: true)..startTurn(3);
      r.handle(_n('session/reasoningDelta', {'requestId': 3, 'text': 'somo 17 '}));
      r.handle(_n('session/reasoningDelta', {'requestId': 3, 'text': 'e 25'}));
      r.handle(_n('session/textDelta', {'requestId': 3, 'text': 'O resultado é 42.'}));
      r.endTurn();
      expect(_plain(out), '💭 somo 17 e 25\nO resultado é 42.\n');
      expect(out.toString(), contains('\x1B[0m'), reason: 'the gray must be reset');
    });

    test('is left out when the output is not a terminal, so a redirect keeps only the answer', () {
      final out = StringBuffer();
      final r = TurnRenderer(out: out, tty: false)..startTurn(3);
      r.handle(_n('session/reasoningDelta', {'requestId': 3, 'text': 'pensando'}));
      r.handle(_n('session/textDelta', {'requestId': 3, 'text': 'resposta'}));
      r.endTurn();
      expect(_plain(out), 'resposta\n');
    });

    test('says when old messages were left out to fit the model window, and ignores other turns',
        () {
      final out = StringBuffer();
      final r = TurnRenderer(out: out, tty: true)..startTurn(5);
      r.handle(
          _n('session/contextTrimmed', {'requestId': 5, 'droppedMessages': 4, 'keptMessages': 6}));
      r.handle(_n('session/textDelta', {'requestId': 99, 'text': 'de outro turno'}));
      expect(_plain(out), contains('4 older message(s)'));
      expect(_plain(out), isNot(contains('outro turno')));
    });
  });

  group('usage notice', () {
    late Directory home, workspace;
    setUp(() {
      home = Directory.systemTemp.createTempSync('notice_home_');
      workspace = Directory.systemTemp.createTempSync('notice_ws_');
    });
    tearDown(() {
      home.deleteSync(recursive: true);
      workspace.deleteSync(recursive: true);
    });

    void config(Directory d, String yaml) {
      File('${d.path}/.shepherd/ai_config.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync(yaml);
    }

    test('is shown once, and says what is and is not sent', () {
      final first = UsageNotice.takeIfDue(workspace: workspace, home: home);
      expect(first, isNotNull);
      expect(first, allOf(contains('never sent'), contains('telemetry: false')));
      expect(UsageNotice.takeIfDue(workspace: workspace, home: home), isNull, reason: 'only once');
    });

    test('is not shown when the report is turned off, and then it is not consumed either', () {
      config(workspace, 'telemetry: false\n');
      expect(UsageNotice.takeIfDue(workspace: workspace, home: home), isNull);
      // Turned on again later: the user has still not been told.
      config(workspace, 'telemetry: true\n');
      expect(UsageNotice.takeIfDue(workspace: workspace, home: home), isNotNull);
    });

    test('the folder config wins over the home config, and nothing set means on', () {
      expect(UsageNotice.reportIsOn(workspace: workspace, home: home), isTrue);
      config(home, 'telemetry: false\n');
      expect(UsageNotice.reportIsOn(workspace: workspace, home: home), isFalse);
      config(workspace,
          'active_provider: ollama\n'); // the folder file exists and says nothing: default
      expect(UsageNotice.reportIsOn(workspace: workspace, home: home), isTrue);
    });
  });
}

void hintTests() {
  group('prompt hint', () {
    tearDown(() => I18n.use(ShepherdLang.en));
    String plain(String s) => s.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');

    test('lists the commands with what they do, and fits the terminal', () {
      I18n.use(ShepherdLang.en);
      final wide = plain(TerminalChat.promptHint(140));
      for (final c in ['/plan', '/auto', '/fast', '/model', '/projects', '/help', 'exit']) {
        expect(wide, contains(c));
      }
      expect(wide, contains('carry out the plan'));
      final narrow = plain(TerminalChat.promptHint(60));
      expect(narrow, isNot(contains('carry out the plan')));
      expect(narrow, contains('/projects'));
      for (final line in narrow.split('\n')) {
        expect(line.length, lessThanOrEqualTo(60));
      }
    });

    test('follows the language', () {
      I18n.use(ShepherdLang.pt);
      expect(plain(TerminalChat.promptHint(140)), contains('sair'));
    });
  });
}
