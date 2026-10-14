import 'package:shepherd/src/i18n/i18n.dart';
import 'package:shepherd/src/i18n/lang.dart';
import 'package:shepherd/src/menu/presentation/cli/direct_commands.dart';
import 'package:shepherd/src/utils/cli_parser.dart';
import 'package:shepherd/src/version.dart';
import 'package:test/test.dart';

void main() {
  tearDown(I18n.reset);

  test(
      'the help lists every command the CLI has, including ai, login, mcp, lang',
      () {
    I18n.use(ShepherdLang.en);
    final text = DirectCommandsMenu.helpText();
    for (final c in [
      'shell', 'init', 'clean', 'changelog', 'flow', 'update', 'deploy',
      'login', 'mcp', 'lang', 'ai config', 'ai model', 'ai --update-engine',
      'ai --plan | --auto', 'version', 'about', //
    ]) {
      expect(text, contains(c), reason: c);
    }
    expect(text, isNot(contains('Gemini model')));
  });

  test('every command in the help exists in the parser or is handled before it',
      () {
    final parser = buildShepherdArgParser();
    final known = {...parser.commands.keys, 'ai', 'shell', 'lang'};
    final text = DirectCommandsMenu.helpText();
    final names = RegExp(r'^  ([a-z-]+)', multiLine: true)
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();
    expect(known.containsAll(names.where((n) => n != 'shepherd')), isTrue,
        reason: '${names.difference(known)}');
  });

  test('the help follows the language', () {
    I18n.use(ShepherdLang.pt);
    expect(DirectCommandsMenu.helpText(), contains('Ajuda do Shepherd CLI'));
    I18n.use(ShepherdLang.es);
    expect(DirectCommandsMenu.helpText(), contains('Ayuda de Shepherd CLI'));
    I18n.use(ShepherdLang.en);
    expect(DirectCommandsMenu.helpText(), contains('Shepherd CLI Help'));
  });

  test('the automation help leaves out the AI and the direct commands', () {
    I18n.use(ShepherdLang.en);
    final text = DirectCommandsMenu.helpText(automation: true);
    expect(text, contains('clean'));
    expect(text, isNot(contains('ai config')));
  });

  test('a command has its own help, an unknown one has none', () {
    I18n.use(ShepherdLang.en);
    expect(DirectCommandsMenu.printCommandHelp('update'), isTrue);
    expect(DirectCommandsMenu.printCommandHelp('nope'), isFalse);
  });

  test('about shows the real version', () {
    expect(shepherdVersion, isNotEmpty);
  });
}
