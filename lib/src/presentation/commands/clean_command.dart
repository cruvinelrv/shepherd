import 'dart:io';

Future<void> runCleanCommand(List<String> args) async {
  final onlyCurrent = args.isNotEmpty && args.first == 'project';
  final root = Directory.current;
  final pubspecFiles = <File>[];

  if (onlyCurrent) {
    final pubspec = File('{root.path}/pubspec.yaml');
    if (await pubspec.exists()) {
      pubspecFiles.add(pubspec);
    } else {
      print('No pubspec.yaml found in the current directory.');
      exit(1);
    }
  } else {
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('pubspec.yaml')) {
        pubspecFiles.add(entity);
      }
    }
    if (pubspecFiles.isEmpty) {
      print('No pubspec.yaml found in the project.');
      exit(1);
    }
  }

  for (final pubspec in pubspecFiles) {
    final dir = pubspec.parent;
    print('\n--- Cleaning: \u001b[1m${dir.path}\u001b[0m ---');
    final pubspecLock = File('${dir.path}/pubspec.lock');
    if (await pubspecLock.exists()) {
      await pubspecLock.delete();
      print('Removed pubspec.lock');
    }
    final cleanResult = await Process.run('flutter', ['clean'], workingDirectory: dir.path);
    stdout.write(cleanResult.stdout);
    stderr.write(cleanResult.stderr);
    final pubGetResult = await Process.run('flutter', ['pub', 'get'], workingDirectory: dir.path);
    stdout.write(pubGetResult.stdout);
    stderr.write(pubGetResult.stderr);
    print('--- Cleaning finished in: ${dir.path} ---');
  }
  print('\nCleaning finished!');
}
