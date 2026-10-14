import 'package:shepherd/src/ai_client/command_hints.dart';
import 'package:shepherd/src/ai_client/terminal_chat.dart';
import 'package:test/test.dart';

void main() {
  runPromptTests();
  test(
      'flutter run without a device warns that any connected phone can be picked',
      () {
    expect(commandHints('flutter run'), ['cmd.hint_no_device']);
    expect(commandHints('cd app && flutter run --release'),
        ['cmd.hint_no_device']);
    expect(commandHints('flutter run -d chrome'), isEmpty);
    expect(commandHints('flutter run --device-id=chrome'), isEmpty);
    expect(commandHints('flutter run --device-id chrome'), isEmpty);
  });

  test('flutter create without --platforms warns that it makes every platform',
      () {
    expect(commandHints('flutter create app'), ['cmd.hint_all_platforms']);
    expect(commandHints('flutter create --platforms=web app'), isEmpty);
    expect(commandHints('flutter create app --platforms web,android'), isEmpty);
  });

  test('both in one block, once each; other commands are left alone', () {
    expect(commandHints('flutter create app\ncd app\nflutter run\nflutter run'),
        ['cmd.hint_all_platforms', 'cmd.hint_no_device']);
    expect(commandHints('git status'), isEmpty);
    expect(commandHints('flutter pub get'), isEmpty);
    expect(commandHints(''), isEmpty);
  });
}

void runPromptTests() {
  group('what /run sends', () {
    test(
        'carries the request and the plan in writing, and the rule to keep names',
        () {
      final p = runPlanPrompt('create the project MarmeloSpace, flutter web',
          '1. flutter create --platforms=web marmelo_space', '');
      expect(p, startsWith(runPrefix));
      expect(p, contains('keep every name'));
      expect(p, contains('MarmeloSpace, flutter web'));
      expect(p, contains('--platforms=web marmelo_space'));
      expect(p, isNot(contains('The user also says')));
    });

    test('what the user adds after /run goes in too', () {
      expect(runPlanPrompt('a', 'b', 'now I need to run it'),
          contains('The user also says: now I need to run it'));
    });

    test(
        'without a plan to quote it points at the conversation; long text is cut',
        () {
      expect(runPlanPrompt('', '', ''), contains('the one above'));
      final long = runPlanPrompt('x', 'y' * 20000, '');
      expect(long.length, lessThan(9000));
      expect(long, contains('[...]'));
    });
  });
}
