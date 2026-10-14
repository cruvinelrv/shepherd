import '../i18n/i18n.dart';
import '../utils/ansi_colors.dart';

/// A colored view of a file change for the terminal: how the user decides
/// whether to apply it. Only a display; the engine owns what gets written.
String renderDiff(
    {required String path,
    required String? original,
    required String content,
    int context = 2,
    int maxLines = 80}) {
  final b = StringBuffer();
  final isNew = original == null;
  b.writeln(
      '${AnsiColors.bold}${AnsiColors.brightCyan}--- $path ${t(isNew ? 'diff.new_file' : 'diff.modification')}${AnsiColors.reset}');
  final newLines = content.split('\n');
  if (newLines.isNotEmpty && newLines.last.isEmpty) newLines.removeLast();

  if (isNew) {
    for (final l in newLines.take(maxLines)) {
      b.writeln('${AnsiColors.brightGreen}+ $l${AnsiColors.reset}');
    }
    if (newLines.length > maxLines) {
      b.writeln('${AnsiColors.gray}${t('diff.more_lines', {
            'n': newLines.length - maxLines
          })}${AnsiColors.reset}');
    }
    return b.toString();
  }

  final oldLines = original.split('\n');
  if (oldLines.isNotEmpty && oldLines.last.isEmpty) oldLines.removeLast();
  final ops = _lineDiff(oldLines, newLines);
  if (ops == null) {
    b.writeln('${AnsiColors.gray}${t('diff.too_big', {
          'old': oldLines.length,
          'new': newLines.length
        })}${AnsiColors.reset}');
    return b.toString();
  }
  if (ops.every((o) => o.kind == ' ')) {
    b.writeln('${AnsiColors.gray}${t('diff.no_changes')}${AnsiColors.reset}');
    return b.toString();
  }

  // Show the changes with a little context, and fold the unchanged stretches.
  final show = List<bool>.filled(ops.length, false);
  for (var i = 0; i < ops.length; i++) {
    if (ops[i].kind != ' ') {
      for (var k = (i - context).clamp(0, ops.length - 1);
          k <= (i + context).clamp(0, ops.length - 1);
          k++) {
        show[k] = true;
      }
    }
  }
  var printed = 0;
  var folded = false;
  for (var i = 0; i < ops.length; i++) {
    if (!show[i]) {
      folded = true;
      continue;
    }
    if (folded) {
      b.writeln('${AnsiColors.gray}  ...${AnsiColors.reset}');
      folded = false;
    }
    if (printed++ >= maxLines) {
      b.writeln('${AnsiColors.gray}${t('diff.continues')}${AnsiColors.reset}');
      break;
    }
    final o = ops[i];
    switch (o.kind) {
      case '-':
        b.writeln('${AnsiColors.brightRed}- ${o.text}${AnsiColors.reset}');
      case '+':
        b.writeln('${AnsiColors.brightGreen}+ ${o.text}${AnsiColors.reset}');
      default:
        b.writeln('  ${o.text}');
    }
  }
  return b.toString();
}

class _Op {
  final String kind; // ' ', '-', '+'
  final String text;
  const _Op(this.kind, this.text);
}

/// Line diff by longest common subsequence; null for files too big for the table.
List<_Op>? _lineDiff(List<String> a, List<String> b) {
  final n = a.length, m = b.length;
  if (n * m > 4000000) return null;
  final w = m + 1;
  final t = List<int>.filled((n + 1) * w, 0);
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      t[i * w + j] = a[i] == b[j]
          ? t[(i + 1) * w + j + 1] + 1
          : (t[(i + 1) * w + j] >= t[i * w + j + 1]
              ? t[(i + 1) * w + j]
              : t[i * w + j + 1]);
    }
  }
  final out = <_Op>[];
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      out.add(_Op(' ', a[i]));
      i++;
      j++;
    } else if (t[(i + 1) * w + j] >= t[i * w + j + 1]) {
      out.add(_Op('-', a[i++]));
    } else {
      out.add(_Op('+', b[j++]));
    }
  }
  while (i < n) {
    out.add(_Op('-', a[i++]));
  }
  while (j < m) {
    out.add(_Op('+', b[j++]));
  }
  return out;
}
