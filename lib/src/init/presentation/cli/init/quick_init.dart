import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../i18n/i18n.dart';
import '../../../../utils/ansi_colors.dart';
import 'quick_init_files.dart';
import 'quick_init_git.dart';

/// Where the quick init talks to the person; replaced in tests.
class QuickInitIO {
  final String? Function() readLine;
  final void Function(String) say;
  final void Function(String) ask;

  QuickInitIO({
    String? Function()? readLine,
    void Function(String)? say,
    void Function(String)? ask,
  })  : readLine = readLine ?? (() => stdin.readLineSync()),
        say = say ?? print,
        ask = ask ?? stdout.write;
}

/// `shepherd init [--yes] [--name <name>] [--repo github|azure|later]
/// [--user "First Last"] [--email <email>] [--github <username>]`
///
/// One standard workspace, always: the answers it needs have a default (Enter),
/// everything else is assumed and shown at the end. It creates no git repository:
/// the workspace folder only holds `.shepherd/`, git belongs to each project in it. Returns the exit code.
Future<int> runQuickInit(
  List<String> args, {
  QuickInitIO? io,
  Directory? dir,
  GitProbe Function(String dir)? gitFor,
}) async {
  final out = io ?? QuickInitIO();
  final opts = _Options.parse(args);
  var here = dir ?? Directory.current;
  var git = (gitFor ?? (d) => GitProbe(d))(here.path);
  final interactive = !opts.yes;

  String answer(String question, String fallback) {
    if (!interactive) return fallback;
    out.ask(fallback.isEmpty ? '$question: ' : '$question [$fallback]: ');
    final line = out.readLine()?.trim() ?? '';
    return line.isEmpty ? fallback : line;
  }

  if (isInitialized(here)) {
    out.say('${AnsiColors.yellow}${t('qi.already')}${AnsiColors.reset}');
    if (!interactive) return 1;
    out.ask(t('qi.continue_anyway'));
    if (!_yes(out.readLine())) {
      out.say(t('qi.cancelled'));
      return 1;
    }
  }

  out.say('\n${AnsiColors.bold}${t('qi.title')}${AnsiColors.reset}');
  out.say(t('qi.intro'));

  // 1. The workspace's name, and the folder it lives in
  final folder = p.basename(here.path);
  var name = opts.name ?? answer(t('qi.ask_name'), folder);
  while (name.isEmpty || name.contains(RegExp(r'[\\/]'))) {
    out.say(t('qi.bad_name'));
    if (!interactive) return 1;
    name = answer(t('qi.ask_name'), folder);
  }
  if (name != folder) {
    out.ask(t('qi.new_folder', {'name': name}));
    final line = interactive ? out.readLine()?.trim() ?? '' : 'y';
    if (line.isEmpty || _yes(line)) {
      final created = Directory(p.join(here.path, name));
      created.createSync(recursive: true);
      here = created;
      git = (gitFor ?? (d) => GitProbe(d))(here.path);
    }
  }

  // 2. Who you are (git knows, usually)
  final gitUser = await git.user;
  final parts = (opts.user ?? gitUser.name).trim().split(RegExp(r'\s+'));
  final guessFirst = parts.first;
  final guessLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';
  final fullName = answer(t('qi.ask_user'), '$guessFirst $guessLast'.trim());
  if (fullName.isEmpty) {
    out.say(t('qi.need_user'));
    return 1;
  }
  final email = opts.email ?? answer(t('qi.ask_email'), gitUser.email);
  final names = fullName.split(RegExp(r'\s+'));
  final firstName = names.first;
  final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

  // 3. The trunk: `main`, or the branch of the repository this folder already is
  // (a workspace folder is not a repository itself; each project in it has its own)
  final trunk = await git.isRepository ? await git.trunk : 'main';

  // 4. Where the code will live
  var repoType = opts.repo ?? await git.remoteType;
  if (repoType == null) {
    var choice = answer(t('qi.ask_repo'), 'later').toLowerCase();
    while (!const {'github', 'azure', 'later'}.contains(choice)) {
      out.say(t('qi.bad_repo'));
      choice = answer(t('qi.ask_repo'), 'later').toLowerCase();
    }
    repoType = choice;
  }
  if (repoType == 'later') repoType = null;
  String? githubUser = opts.github;
  if (repoType == 'github' && githubUser == null && interactive) {
    githubUser = answer(t('qi.ask_github'), '');
    if (githubUser.isEmpty) githubUser = null;
  }

  // 5. Write it all
  final plan = QuickInitPlan(
    name: name,
    firstName: firstName,
    lastName: lastName,
    email: email,
    trunk: trunk,
    repoType: repoType,
    githubUsername: githubUser,
  );
  await writeQuickInit(plan, here);

  // 6. What was done and what was assumed
  out.say('\n${AnsiColors.brightGreen}${t('qi.done', {
        'name': name
      })}${AnsiColors.reset}');
  out.say('  ${t('qi.sum_where', {'path': here.path})}');
  out.say('  ${t('qi.sum_user', {'user': fullName, 'email': email})}');
  out.say('  ${t('qi.sum_env', {'trunk': trunk})}');
  out.say('  ${t('qi.sum_repo', {'repo': repoType ?? t('qi.repo_later')})}');
  out.say('\n${t('qi.change')}');
  return 0;
}

bool _yes(String? s) => {
      'y',
      'yes',
      's',
      'sim',
      'si',
      's${String.fromCharCode(0xed)}'
    }.contains(s?.trim().toLowerCase());

class _Options {
  final bool yes;
  final String? name, repo, user, email, github;

  const _Options(
      this.yes, this.name, this.repo, this.user, this.email, this.github);

  static _Options parse(List<String> args) {
    String? value(String flag) {
      final i = args.indexOf(flag);
      if (i >= 0 && i + 1 < args.length) return args[i + 1];
      for (final a in args) {
        if (a.startsWith('$flag=')) return a.substring(flag.length + 1);
      }
      return null;
    }

    final repo = value('--repo')?.toLowerCase();
    return _Options(
      args.contains('--yes') || args.contains('-y'),
      value('--name'),
      const {'github', 'azure', 'later'}.contains(repo) ? repo : null,
      value('--user'),
      value('--email'),
      value('--github'),
    );
  }
}
