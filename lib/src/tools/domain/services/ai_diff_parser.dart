import '../entities/ai_file_action_entity.dart';
import '../../data/models/ai_file_action_model.dart';

/// A diff the model sent that could not be turned into a safe file change.
class AiDiffFailure {
  final String path;
  final String reason;
  const AiDiffFailure(this.path, this.reason);
}

/// What was recovered from the ```diff blocks of a model answer.
class AiDiffResult {
  final List<AiFileActionEntity> actions;
  final List<AiDiffFailure> failures;
  const AiDiffResult(this.actions, this.failures);
}

class _Hunk {
  final int oldStart;
  final List<String> oldLines = [];
  final List<String> newLines = [];
  _Hunk(this.oldStart);
}

class _FileDiff {
  final String path;
  final bool isNew;
  final List<_Hunk> hunks = [];
  _FileDiff(this.path, {required this.isNew});
}

/// Turns unified diffs (```diff blocks) into whole-file actions.
///
/// Models routinely invent line numbers and paths, so a diff is only applied
/// when every hunk's context and removed lines match the real file exactly
/// (trailing whitespace aside). The stated line numbers are just a hint.
/// Anything else is reported as a failure instead of being guessed at.
class AiDiffParser {
  static final _fence = RegExp(r'```(?:diff|patch)[ \t]*\r?\n([\s\S]*?)```');
  static final _hunkHeader = RegExp(r'^@@ -(\d+)(?:,\d+)? \+\d+(?:,\d+)? @@');

  /// [readOriginal] returns the current content of [path], or null when the
  /// file does not exist.
  static AiDiffResult parse(
    String text, {
    required String? Function(String path) readOriginal,
  }) {
    final actions = <AiFileActionEntity>[];
    final failures = <AiDiffFailure>[];
    for (final block in _fence.allMatches(text)) {
      for (final diff in _split(block.group(1)!)) {
        final original = readOriginal(diff.path);
        final result = _apply(diff, original);
        if (result == null) {
          failures.add(AiDiffFailure(
              diff.path,
              original == null
                  ? 'o arquivo não existe e o diff não o cria'
                  : 'o diff não corresponde ao conteúdo atual do arquivo '
                      '(o modelo provavelmente não viu o arquivo real)'));
          continue;
        }
        actions.add(AiFileActionModel(
          path: diff.path,
          actionType: original == null
              ? AiFileActionType.create
              : AiFileActionType.modify,
          newContent: result,
          originalContent: original,
        ));
      }
    }
    return AiDiffResult(actions, failures);
  }

  static String _cleanPath(String raw) =>
      raw.split('\t').first.trim().replaceAll('\\', '/');

  static List<_FileDiff> _split(String body) {
    final diffs = <_FileDiff>[];
    final lines = body.split(RegExp(r'\r?\n'));
    // The newline that closes the block is not a blank context line.
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
    _FileDiff? file;
    _Hunk? hunk;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('--- ') &&
          i + 1 < lines.length &&
          lines[i + 1].startsWith('+++ ')) {
        var oldPath = _cleanPath(line.substring(4));
        var newPath = _cleanPath(lines[i + 1].substring(4));
        i++;
        if (newPath == '/dev/null') {
          file = null; // deletions are never applied from a diff
          hunk = null;
          continue;
        }
        if (oldPath.startsWith('a/') && newPath.startsWith('b/')) {
          oldPath = oldPath.substring(2);
          newPath = newPath.substring(2);
        }
        file = _FileDiff(newPath, isNew: oldPath == '/dev/null');
        diffs.add(file);
        hunk = null;
        continue;
      }
      if (file == null) continue;
      final header = _hunkHeader.firstMatch(line);
      if (header != null) {
        hunk = _Hunk(int.parse(header.group(1)!));
        file.hunks.add(hunk);
        continue;
      }
      if (hunk == null || line.startsWith('\\')) continue;
      if (line.startsWith('+')) {
        hunk.newLines.add(line.substring(1));
      } else if (line.startsWith('-')) {
        hunk.oldLines.add(line.substring(1));
      } else {
        // Context line; a bare empty line is a blank context line whose
        // leading space the model dropped.
        final ctx = line.startsWith(' ') ? line.substring(1) : line;
        hunk.oldLines.add(ctx);
        hunk.newLines.add(ctx);
      }
    }
    return diffs.where((d) => d.hunks.isNotEmpty).toList();
  }

  static String _t(String s) => s.trimRight();

  /// Index where [needle] sits in [hay] at or after [from], or -1. With a
  /// non-unique match, only the one at [hint] is accepted.
  static int _locate(
      List<String> hay, List<String> needle, int from, int hint) {
    bool at(int i) {
      if (i < 0 || i + needle.length > hay.length) return false;
      for (var k = 0; k < needle.length; k++) {
        if (_t(hay[i + k]) != _t(needle[k])) return false;
      }
      return true;
    }

    if (at(hint) && hint >= from) return hint;
    var found = -1;
    for (var i = from; i + needle.length <= hay.length; i++) {
      if (at(i)) {
        if (found != -1) return -1; // ambiguous
        found = i;
      }
    }
    return found;
  }

  static String? _apply(_FileDiff diff, String? original) {
    if (original == null) {
      if (!diff.isNew && diff.hunks.any((h) => h.oldLines.isNotEmpty)) {
        return null;
      }
      final added = [for (final h in diff.hunks) ...h.newLines];
      return added.isEmpty ? null : '${added.join('\n')}\n';
    }
    if (diff.isNew) return null; // "create" over a file that already exists

    final crlf = original.contains('\r\n');
    var content = crlf ? original.replaceAll('\r\n', '\n') : original;
    final trailingNewline = content.endsWith('\n');
    final lines = content.split('\n');
    if (trailingNewline) lines.removeLast();

    var from = 0;
    for (final h in diff.hunks) {
      if (h.oldLines.isEmpty) return null; // nowhere to anchor an insertion
      final at = _locate(lines, h.oldLines, from, h.oldStart - 1);
      if (at == -1) return null;
      lines.replaceRange(at, at + h.oldLines.length, h.newLines);
      from = at + h.newLines.length;
    }
    content = lines.join('\n') + (trailingNewline ? '\n' : '');
    return crlf ? content.replaceAll('\n', '\r\n') : content;
  }
}
