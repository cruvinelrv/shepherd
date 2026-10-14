/// Notes shown under a proposed command when it leaves out something that usually
/// matters, as catalog keys (see `cmd.hint_*`). They only inform: the user decides.
List<String> commandHints(String command) {
  final hints = <String>[];
  for (final line in command.split(RegExp(r'\n|&&|;|\|\|'))) {
    final words = line.trim().split(RegExp(r'\s+'));
    if (words.length < 2 || words.first != 'flutter') continue;
    final flags = words.skip(2).toList();
    bool has(List<String> names) => flags.any((f) =>
        names.contains(f) ||
        names.any((n) => n.startsWith('--') && f.startsWith('$n=')));
    switch (words[1]) {
      case 'run':
        if (!has(['-d', '--device-id'])) hints.add('cmd.hint_no_device');
      case 'create':
        if (!has(['--platforms'])) hints.add('cmd.hint_all_platforms');
    }
  }
  return hints.toSet().toList();
}
