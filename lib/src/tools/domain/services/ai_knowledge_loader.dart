import 'dart:io';

import 'package:path/path.dart' as p;

import 'workspace_manifest_service.dart';

/// Instructions, skills and specs the user wrote as plain Markdown, in the
/// shape people already know from Claude:
///
/// - `.shepherd/SHEPHERD.md`        general instructions (like CLAUDE.md)
/// - `.shepherd/skills/<name>/SKILL.md`  a skill: `name` and `description`
///   in a `---` header, instructions below
/// - `.shepherd/specs/<name>.md`    a specification
///
/// Each exists at the workspace root and inside every project folder; the
/// project's own take precedence on conflict, so they are listed last.
class AiKnowledge {
  final String workspaceRoot;

  /// Total size cap so a big folder cannot swamp the model's context.
  final int maxChars;

  const AiKnowledge(this.workspaceRoot, {this.maxChars = 24000});

  /// [projects]: the selected folders; empty means every project in the
  /// manifest.
  String read({List<String> projects = const []}) {
    final folders = projects.isNotEmpty ? projects : _manifestFolders();
    final sources = <({String label, String dir})>[
      (label: 'workspace', dir: workspaceRoot),
      for (final f in folders)
        (label: 'projeto $f', dir: p.join(workspaceRoot, f)),
    ];

    final out = StringBuffer();
    for (final s in sources) {
      final text = _readLevel(s.label, s.dir);
      if (text.isEmpty) continue;
      if (out.length + text.length > maxChars) {
        out.writeln(
            '(Mais instruções em ${s.label} foram omitidas: limite de tamanho.)');
        break;
      }
      out.writeln(text);
    }
    return out.toString().trim();
  }

  List<String> _manifestFolders() {
    final m = WorkspaceManifest.tryLoad();
    if (m == null) return const [];
    return [for (final pr in m.projects) pr.path.replaceAll('\\', '/')];
  }

  String _readLevel(String label, String dir) {
    final b = StringBuffer();
    final rules = _read(p.join(dir, '.shepherd', 'SHEPHERD.md'));
    if (rules != null) {
      b
        ..writeln('--- Instruções ($label) ---')
        ..writeln(rules)
        ..writeln();
    }
    for (final skill in readSkills(dir)) {
      b
        ..writeln('--- Skill "${skill.name}" ($label) ---')
        ..writeln('Use quando: ${skill.description}')
        ..writeln(skill.body)
        ..writeln();
    }
    for (final spec in readSpecs(dir)) {
      b
        ..writeln('--- Especificação "${spec.name}" ($label) ---')
        ..writeln(spec.body)
        ..writeln();
    }
    return b.toString();
  }

  static String? _read(String path) {
    final f = File(path);
    if (!f.existsSync()) return null;
    final t = f.readAsStringSync().trim();
    return t.isEmpty ? null : t;
  }

  static List<({String name, String description, String body})> readSkills(
    String dir,
  ) {
    final root = Directory(p.join(dir, '.shepherd', 'skills'));
    if (!root.existsSync()) return const [];
    final found = <({String name, String description, String body})>[];
    final folders = root.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final d in folders) {
      final text = _read(p.join(d.path, 'SKILL.md'));
      if (text == null) continue;
      final parsed = parseFrontMatter(text);
      found.add((
        name: parsed.meta['name'] ?? p.basename(d.path),
        description: parsed.meta['description'] ?? '',
        body: parsed.body,
      ));
    }
    return found;
  }

  static List<({String name, String body})> readSpecs(String dir) {
    final root = Directory(p.join(dir, '.shepherd', 'specs'));
    if (!root.existsSync()) return const [];
    final files = root
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return [
      for (final f in files)
        if (_read(f.path) case final t?)
          (name: p.basenameWithoutExtension(f.path), body: t),
    ];
  }

  /// Splits an optional `---` YAML-ish header (`key: value` lines) from the body.
  static ({Map<String, String> meta, String body}) parseFrontMatter(
    String text,
  ) {
    final match =
        RegExp(r'^---\s*\n([\s\S]*?)\n---\s*(?:\n|$)').firstMatch(text);
    if (match == null) return (meta: const {}, body: text.trim());
    final meta = <String, String>{};
    for (final line in match.group(1)!.split('\n')) {
      final i = line.indexOf(':');
      if (i <= 0) continue;
      var v = line.substring(i + 1).trim();
      if (v.length >= 2 &&
          (v.startsWith('"') && v.endsWith('"') ||
              v.startsWith("'") && v.endsWith("'"))) {
        v = v.substring(1, v.length - 1);
      }
      meta[line.substring(0, i).trim()] = v;
    }
    return (meta: meta, body: text.substring(match.end).trim());
  }
}
