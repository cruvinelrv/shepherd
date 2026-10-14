import '../../../i18n/i18n.dart';
import '../../../version.dart';

/// One line of the help: the command as typed and the catalog key of its text.
typedef HelpRow = (String, String);

/// `shepherd help`, `shepherd <command> --help` and `shepherd about`.
class DirectCommandsMenu {
  static const _direct = <HelpRow>[
    ('shell', 'hp.shell'),
    ('init', 'hp.init'),
    ('pull', 'hp.pull'),
    ('analyze', 'hp.analyze'),
    ('export-yaml', 'hp.export_yaml'),
    ('add-owner', 'hp.add_owner'),
  ];

  static const _automation = <HelpRow>[
    ('clean', 'hp.clean'),
    ('changelog', 'hp.changelog'),
    ('flow', 'hp.flow'),
    ('gitrecover', 'hp.gitrecover'),
    ('update', 'hp.update'),
    ('auto-update', 'hp.auto_update'),
    ('deploy', 'hp.deploy'),
    ('tag gen', 'hp.tag_gen'),
    ('test gen', 'hp.test_gen'),
    ('story <add|list>', 'hp.story'),
    ('task <add|list>', 'hp.task'),
    ('element <add|list>', 'hp.element'),
  ];

  static const _ai = <HelpRow>[
    ('ai "..."', 'hp.ai'),
    ('ai', 'hp.ai_chat'),
    ('ai --plan | --auto', 'hp.ai_mode'),
    ('ai --projects a,b', 'hp.ai_projects'),
    ('ai -f <file>', 'hp.ai_file'),
    ('ai model [name]', 'hp.ai_model'),
    ('ai config', 'hp.ai_config'),
    ('ai --update-engine', 'hp.ai_engine'),
  ];

  static const _account = <HelpRow>[
    ('login', 'hp.login'),
    ('mcp [list|status|call]', 'hp.mcp'),
    ('lang [en|pt|es]', 'hp.lang'),
  ];

  static const _info = <HelpRow>[
    ('help', 'hp.help'),
    ('version', 'hp.version'),
    ('about', 'hp.about'),
  ];

  /// Every command with its text, for `shepherd <command> --help`.
  static final _byCommand = {
    for (final r in [
      ..._direct,
      ..._automation,
      ..._ai,
      ..._account,
      ..._info,
    ])
      r.$1.split(' ').first: r,
  };

  static void _section(StringBuffer b, String titleKey, List<HelpRow> rows) {
    b.writeln(t(titleKey));
    for (final (cmd, key) in rows) {
      b.writeln('  ${cmd.padRight(24)} ${t(key)}');
    }
    b.writeln();
  }

  static String helpText({bool automation = false}) {
    final b = StringBuffer()
      ..writeln(t(automation ? 'hp.title_auto' : 'hp.title'))
      ..writeln()
      ..writeln(t('hp.usage'))
      ..writeln('  shepherd <command> [options]')
      ..writeln();
    if (!automation) _section(b, 'hp.sec_direct', _direct);
    _section(b, 'hp.sec_auto', _automation);
    if (!automation) {
      _section(b, 'hp.sec_ai', _ai);
      _section(b, 'hp.sec_account', _account);
      b
        ..writeln(t('hp.sec_menus'))
        ..writeln('  ${t('hp.menus_intro')}')
        ..writeln('    - Domains      ${t('hp.menu_domains')}')
        ..writeln('    - Config       ${t('hp.menu_config')}')
        ..writeln('    - Deploy       ${t('hp.menu_deploy')}')
        ..writeln('    - Tools        ${t('hp.menu_tools')}')
        ..writeln();
    }
    _section(b, 'hp.sec_info', _info);
    b
      ..writeln(t('hp.examples'))
      ..writeln('  shepherd shell        ${t('hp.ex_shell')}')
      ..writeln('  shepherd ai "..."     ${t('hp.ex_ai')}')
      ..writeln('  shepherd clean        ${t('hp.ex_clean')}')
      ..writeln('  shepherd lang pt      ${t('hp.ex_lang')}')
      ..writeln()
      ..writeln(t('hp.more'))
      ..writeln('  shepherd <command> --help');
    return b.toString();
  }

  static void printShepherdHelp() => print(helpText());

  static void printAutomationHelp() => print(helpText(automation: true));

  /// Help for one command; false when [command] is not one the CLI has.
  static bool printCommandHelp(String command) {
    final row = _byCommand[command.toLowerCase()];
    if (row == null) return false;
    final b = StringBuffer()
      ..writeln(t(row.$2))
      ..writeln()
      ..writeln('${t('hp.usage')} shepherd ${row.$1} [options]');
    if (command.toLowerCase() == 'update') {
      b
        ..writeln()
        ..writeln(t('hp.options'))
        ..writeln('  --check        ${t('hp.opt_check')}')
        ..writeln('  -y, --yes      ${t('hp.opt_yes')}');
    }
    print(b.toString().trimRight());
    return true;
  }

  static void printShepherdAbout() {
    print('''
Shepherd CLI v$shepherdVersion
${'=' * (14 + shepherdVersion.length)}
${t('hp.about_tagline')}
${t('hp.about_by', {'url': 'https://marmelo.tech'})}

${t('hp.about_platform')}
${t('hp.about_docs')}
${t('hp.about_repo')}
${t('hp.about_author')}
${t('hp.about_license')}
''');
  }
}
