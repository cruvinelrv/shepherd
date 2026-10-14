import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../i18n/i18n.dart';

/// The notice about the usage report, shown once.
///
/// The AI engine reports numbers (provider, model, token counts, duration) to the
/// user's company account in the Shepherd Union, so the company can see how its
/// people use the AI. It is on by default for a logged-in user, so the user is told.
class UsageNotice {
  UsageNotice._();

  /// The notice, in the user's language.
  static String get text => t('notice.usage');

  static Directory _home(Directory? home) =>
      home ??
      Directory(Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '.');

  static File _stamp(Directory? home) =>
      File(p.join(_home(home).path, '.shepherd', '.usage_notice_seen'));

  /// Whether the report is on: `telemetry` in `.shepherd/ai_config.yaml` of this
  /// folder, else of the home folder; on when it says nothing.
  static bool reportIsOn({Directory? workspace, Directory? home}) {
    final files = [
      File(p.join((workspace ?? Directory.current).path, '.shepherd',
          'ai_config.yaml')),
      File(p.join(_home(home).path, '.shepherd', 'ai_config.yaml')),
    ];
    for (final f in files) {
      if (!f.existsSync()) continue;
      try {
        final doc = loadYaml(f.readAsStringSync());
        if (doc is YamlMap && doc['telemetry'] is bool)
          return doc['telemetry'] as bool;
      } catch (_) {}
      return true; // the first file that exists decides; nothing in it, so the default
    }
    return true;
  }

  /// Returns the notice if it has to be shown now (the report is on and the user
  /// was not told yet), and remembers that it was shown.
  static String? takeIfDue({Directory? workspace, Directory? home}) {
    if (!reportIsOn(workspace: workspace, home: home)) return null;
    final stamp = _stamp(home);
    if (stamp.existsSync()) return null;
    try {
      stamp.parent.createSync(recursive: true);
      stamp.writeAsStringSync(DateTime.now().toUtc().toIso8601String());
    } catch (_) {
      // Cannot remember it: showing it every time is better than hiding it.
    }
    return text;
  }
}
