import 'dart:io';

void main(List<String> args) async {
  // Usa o diretório informado ou o atual
  final projectDir = args.isNotEmpty ? args[0] : Directory.current.path;
  // Caminhos relativos ao diretório do projeto
  final changelogFile = File('$projectDir/CHANGELOG.md');
  final pubspecFile = File('$projectDir/mio_vinci_partners/pubspec.yaml');
  final historyFile = File('$projectDir/dev_tools/changelog_history.md');

  // Obter versão do pubspec.yaml
  final pubspecContent = await pubspecFile.readAsString();
  final versionMatch = RegExp(r'version:\s*([0-9]+\.[0-9]+\.[0-9]+)').firstMatch(pubspecContent);
  if (versionMatch == null) {
    print('Versão não encontrada no pubspec.yaml');
    exit(1);
  }
  final pubspecVersion = versionMatch.group(1)!;

  // Ler changelog
  String changelog = await changelogFile.exists() ? await changelogFile.readAsString() : '';
  final lines = changelog.split('\n');

  // Atualizar cabeçalho
  if (lines.isEmpty || !lines.first.startsWith('# CHANGELOG')) {
    lines.insert(0, '# CHANGELOG [$pubspecVersion]');
  } else {
    lines[0] = '# CHANGELOG [$pubspecVersion]';
  }

  // Garantir linha em branco após cabeçalho
  if (lines.length < 2 || lines[1].trim().isNotEmpty) {
    lines.insert(1, '');
  }

  // Detectar versão anterior
  final oldVersionMatch = RegExp(r'# CHANGELOG \[([0-9]+\.[0-9]+\.[0-9]+)\]').firstMatch(changelog);
  final oldVersion = oldVersionMatch?.group(1);
  if (oldVersion != null && oldVersion != pubspecVersion) {
    // Move tudo exceto o cabeçalho para o histórico
    final toArchive = lines.skip(1).join('\n').trim();
    if (toArchive.isNotEmpty) {
      final historyContent =
          await historyFile.exists() ? await historyFile.readAsString() : '# CHANGELOG HISTORY';
      final historyLines = historyContent.split('\n');
      // Garante cabeçalho único
      if (historyLines.isEmpty || !historyLines.first.startsWith('# CHANGELOG HISTORY')) {
        historyLines.insert(0, '# CHANGELOG HISTORY');
      }
      // Adiciona no início do histórico
      historyLines.insert(1, toArchive);
      await historyFile.writeAsString(historyLines.join('\n'));
    }
    // Limpa changelog, mantendo só o cabeçalho
    lines.removeRange(1, lines.length);
    lines.insert(1, '');
  }

  // Data de hoje
  final now = DateTime.now();
  final today =
      '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  final dateHeader = '## [$today]';
  int dateIndex = lines.indexWhere((l) => l.trim() == dateHeader);
  if (dateIndex == -1) {
    lines.insert(2, dateHeader);
    dateIndex = 2;
  }

  // Detectar branch atual do git
  String branch = 'CONTRATTO-XXXX-Descricao-exemplo';
  try {
    final result = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (result.exitCode == 0) {
      branch = result.stdout.toString().trim();
    }
  } catch (_) {}
  final branchId = RegExp(r'([A-Z]+-[0-9]+)').firstMatch(branch)?.group(1) ?? 'CONTRATTO-XXXX';
  final branchDesc = branch.replaceFirst(RegExp(r'^[A-Z]+-[0-9]+-?'), '');
  final entry =
      '- $branchId: ${branchDesc.isNotEmpty ? branchDesc : '(adicione uma descrição)'} [$pubspecVersion]';

  // Evitar duplicidade
  if (!lines.any((l) => l.contains(branchId) && l.contains(pubspecVersion))) {
    lines.insert(dateIndex + 1, entry);
    await changelogFile.writeAsString(lines.join('\n'));
    print('Linha adicionada ao CHANGELOG_dartcode.md: $entry');
  } else {
    print('Atividade já adicionada anteriormente.');
  }
}
