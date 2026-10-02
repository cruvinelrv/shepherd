/// A piece of a streamed model answer.
sealed class AiSplit {
  const AiSplit();
}

/// Prose for the user (file blocks removed).
class AiSplitText extends AiSplit {
  final String text;
  const AiSplitText(this.text);
}

/// A ```lang + `// FILE: path` block just opened; its body is withheld from
/// the text and delivered later as a proposal.
class AiSplitFileStarted extends AiSplit {
  final String path;
  const AiSplitFileStarted(this.path);
}

/// Separates prose from file blocks while the answer streams in. Works line
/// by line: an opening fence is held back until the next line shows whether
/// it starts a `FILE:` block.
class AiStreamSplitter {
  static final _fence = RegExp(r'^```[a-zA-Z0-9_\-+.]*\s*$');
  static final _closing = RegExp(r'^```\s*$');
  static final _fileMarker = RegExp(
    r'^(?://|#|/\*|<!--)\s*(?:FILE|file|ARQUIVO|arquivo):\s*(.+?)\s*(?:\*/|-->)?\s*$',
  );

  String _partial = '';
  String? _heldFence;
  bool _inFile = false;

  List<AiSplit> feed(String chunk) {
    final out = <AiSplit>[];
    _partial += chunk;
    final lines = _partial.split('\n');
    _partial = lines.removeLast();
    for (final line in lines) {
      _line(line.endsWith('\r') ? line.substring(0, line.length - 1) : line, out);
    }
    return out;
  }

  /// Call when the stream ends to release anything still buffered.
  List<AiSplit> flush() {
    final out = <AiSplit>[];
    if (_partial.isNotEmpty) {
      _line(_partial, out, hasNewline: false);
      _partial = '';
    }
    if (_heldFence != null) {
      out.add(AiSplitText(_heldFence!));
      _heldFence = null;
    }
    return out;
  }

  void _line(String line, List<AiSplit> out, {bool hasNewline = true}) {
    final nl = hasNewline ? '\n' : '';
    if (_inFile) {
      if (_closing.hasMatch(line)) _inFile = false;
      return;
    }
    final held = _heldFence;
    if (held != null) {
      _heldFence = null;
      final m = _fileMarker.firstMatch(line);
      if (m != null) {
        _inFile = true;
        out.add(AiSplitFileStarted(m.group(1)!.trim().replaceAll('\\', '/')));
        return;
      }
      out.add(AiSplitText(held));
    }
    if (_fence.hasMatch(line) && hasNewline) {
      _heldFence = '$line\n';
      return;
    }
    out.add(AiSplitText('$line$nl'));
  }
}
