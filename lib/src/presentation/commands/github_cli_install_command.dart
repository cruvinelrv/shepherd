import 'dart:io';

/// Instala o GitHub CLI (gh) automaticamente, detectando a plataforma.
Future<void> runGithubCliInstallCommand(List<String> args) async {
  print('Instalando GitHub CLI (gh)...');
  if (Platform.isMacOS) {
    print('Detectado macOS. Instalando via Homebrew...');
    final result = await Process.run('brew', ['install', 'gh']);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode == 0) {
      print('\x1B[32mGitHub CLI instalado com sucesso!\x1B[0m');
    } else {
      print('\x1B[31mFalha ao instalar o GitHub CLI.\x1B[0m');
    }
  } else if (Platform.isLinux) {
    print('Detectado Linux. Instalando via apt, dnf ou pacotes oficiais...');
    // Tenta apt
    final aptCheck = await Process.run('which', ['apt']);
    if (aptCheck.exitCode == 0) {
      final result = await Process.run('sudo', ['apt', 'install', '-y', 'gh']);
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode == 0) {
        print('\x1B[32mGitHub CLI instalado com sucesso!\x1B[0m');
        return;
      }
    }
    // Tenta dnf
    final dnfCheck = await Process.run('which', ['dnf']);
    if (dnfCheck.exitCode == 0) {
      final result = await Process.run('sudo', ['dnf', 'install', '-y', 'gh']);
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode == 0) {
        print('\x1B[32mGitHub CLI instalado com sucesso!\x1B[0m');
        return;
      }
    }
    print(
        'Por favor, consulte https://cli.github.com/manual/installation para instruções específicas da sua distribuição.');
  } else if (Platform.isWindows) {
    print('Detectado Windows. Instalando via winget...');
    final result = await Process.run('winget', ['install', '--id', 'GitHub.cli', '-e']);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode == 0) {
      print('\x1B[32mGitHub CLI instalado com sucesso!\x1B[0m');
    } else {
      print('\x1B[31mFalha ao instalar o GitHub CLI.\x1B[0m');
      print('Baixe manualmente em: https://cli.github.com/manual/installation');
    }
  } else {
    print('Sistema operacional não suportado para instalação automática.');
    print('Consulte https://cli.github.com/manual/installation para instruções.');
  }
}
