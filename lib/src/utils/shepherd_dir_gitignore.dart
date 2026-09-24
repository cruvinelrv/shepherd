import 'dart:io';

/// Ensures `.shepherd/.gitignore` (relative to the current directory)
/// contains each of [entries], adding whichever are missing without
/// disturbing existing lines — Studio already manages this same file for
/// `environment_variables.yaml`. Anything the CLI stores under `.shepherd/`
/// that's a secret (a session token, an API key) must go through this, since
/// everything else in that folder (workspace.yaml, project.yaml, etc.) is
/// treated as shared, versionable team config.
void ensureShepherdGitignoreEntries(List<String> entries) {
  final file = File('.shepherd/.gitignore');
  if (!file.parent.existsSync()) {
    file.parent.createSync(recursive: true);
  }

  final existing = file.existsSync()
      ? file
          .readAsStringSync()
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList()
      : <String>[];

  if (existing.toSet().containsAll(entries)) return;

  final merged = {...existing, ...entries};
  file.writeAsStringSync('${merged.join('\n')}\n');
}
