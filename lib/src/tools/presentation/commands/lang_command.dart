import 'dart:io';

import '../../../i18n/i18n.dart';
import '../../../i18n/lang.dart';

/// `shepherd lang [en|pt|es]`: shows the interface language or saves a new one.
///
/// Returns the process exit code (0 ok, 1 unknown language).
int runLangCommand(
  List<String> args, {
  void Function(String line)? out,
  Directory? home,
  Map<String, String>? env,
}) {
  final say = out ?? stdout.writeln;
  final environment = env ?? Platform.environment;

  if (args.isNotEmpty) {
    final wanted = parseLang(args.first);
    if (wanted == null) {
      say(t('lang.invalid', {'value': args.first}));
      say(t('lang.options'));
      return 1;
    }
    LangSettings.save(wanted, home: home);
    I18n.use(wanted);
    say(t('lang.saved', {'name': wanted.nativeName}));
    if (parseLang(environment['SHEPHERD_LANG']) != null) {
      say(t('lang.env_wins'));
    }
    return 0;
  }

  final current = LangSettings.resolve(env: environment, home: home);
  final source = parseLang(environment['SHEPHERD_LANG']) != null
      ? t('lang.src_env')
      : LangSettings.saved(home: home) != null
          ? t('lang.src_saved')
          : t('lang.src_auto');
  say(t('lang.current',
      {'name': current.nativeName, 'code': current.name, 'source': source}));
  say(t('lang.options'));
  say(t('lang.usage'));
  return 0;
}
