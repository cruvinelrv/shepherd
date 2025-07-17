import 'dart:io';

void main() async {
  final baseDir = Directory.current.path;
  final folders = [
    '$baseDir/flut_base_app_vinciprev',
    '$baseDir/mio_agi',
    '$baseDir/mio_arklok',
    '$baseDir/mio_vinci_partners',
  ];

  for (final folder in folders) {
    print('\n--- $folder ---');
    final pubspecLock = File('$folder/pubspec.lock');
    if (await pubspecLock.exists()) {
      await pubspecLock.delete();
    }
    final dir = Directory(folder);
    if (!await dir.exists()) {
      print('Pasta não encontrada: $folder');
      continue;
    }
    final cleanResult = await Process.run('flutter', ['clean'], workingDirectory: folder);
    stdout.write(cleanResult.stdout);
    stderr.write(cleanResult.stderr);

    final getResult = await Process.run('flutter', ['pub', 'get'], workingDirectory: folder);
    stdout.write(getResult.stdout);
    stderr.write(getResult.stderr);
  }

  print('Processo concluído!');
}
