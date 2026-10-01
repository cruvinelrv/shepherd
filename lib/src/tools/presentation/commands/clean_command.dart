import 'dart:io';
import 'package:path/path.dart' as p;

const _excludedDirs = {
  '.git',
  '.dart_tool',
  '.shepherd',
  'build',
  'node_modules',
  '.idea',
  '.vscode',
  '.gradle',
  '.fvm',
  'Pods',
  '.Trash',
  '.cache',
  'Pictures',
  'Music',
  'Movies',
  'Library',
  'Applications',
  'System',
};

/// Clean command implementation
Future<void> runCleanCommand(List<String> args) async {
  print('🧹 Starting Shepherd Clean...\n');

  final root = Directory.current;
  final pubspecFiles = <File>[];

  // Check if there's a specific target
  final isProjectSpecific = args.isNotEmpty && args.first == 'project';

  if (isProjectSpecific) {
    // Clean only current project
    final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      pubspecFiles.add(pubspecFile);
      print('📍 Cleaning current project only...');
    } else {
      print('❌ No pubspec.yaml found in the current directory (${root.path}).');
      exitCode = 1;
      return;
    }
  } else {
    // Clean all projects/microfrontends safely
    print('🔍 Searching for pubspec.yaml files safely...');
    pubspecFiles.addAll(await _discoverPubspecs(root));

    if (pubspecFiles.isEmpty) {
      print('❌ No pubspec.yaml files found in this workspace.');
      return;
    }

    print('📦 Found ${pubspecFiles.length} project(s) to clean');
  }

  // Clean each project
  for (final pubspec in pubspecFiles) {
    final dir = pubspec.parent;
    final projectName = p.basename(dir.path);

    print('\n--- 🧽 Cleaning: \x1b[1m$projectName (${dir.path})\x1b[0m ---');

    // Remove pubspec.lock
    final pubspecLock = File(p.join(dir.path, 'pubspec.lock'));
    if (await pubspecLock.exists()) {
      try {
        await pubspecLock.delete();
        print('🗑️  Removed pubspec.lock');
      } catch (e) {
        print('⚠️  Could not remove pubspec.lock: $e');
      }
    }

    // Remove build directory
    final buildDir = Directory(p.join(dir.path, 'build'));
    if (await buildDir.exists()) {
      try {
        await buildDir.delete(recursive: true);
        print('🗑️  Removed build/ directory');
      } catch (e) {
        print('⚠️  Could not remove build/: $e');
      }
    }

    // Remove .dart_tool directory
    final dartToolDir = Directory(p.join(dir.path, '.dart_tool'));
    if (await dartToolDir.exists()) {
      try {
        await dartToolDir.delete(recursive: true);
        print('🗑️  Removed .dart_tool/ directory');
      } catch (e) {
        print('⚠️  Could not remove .dart_tool/: $e');
      }
    }

    // Check if it's a Flutter or pure Dart project
    bool isFlutter = false;
    try {
      final content = await pubspec.readAsString();
      isFlutter = content.contains('sdk: flutter') || content.contains('flutter:');
    } catch (_) {}

    if (isFlutter) {
      // Run flutter clean
      try {
        print('🔧 Running flutter clean...');
        final cleanResult =
            await Process.run('flutter', ['clean'], workingDirectory: dir.path);

        if (cleanResult.exitCode == 0) {
          print('✅ Flutter clean completed');
        } else {
          print('⚠️  Flutter clean had issues: ${cleanResult.stderr}');
        }
      } catch (e) {
        print('⚠️  Could not run flutter clean: $e');
      }

      // Run flutter pub get
      try {
        print('📥 Running flutter pub get...');
        final pubGetResult = await Process.run('flutter', ['pub', 'get'],
            workingDirectory: dir.path);

        if (pubGetResult.exitCode == 0) {
          print('✅ Dependencies restored');
        } else {
          print('⚠️  pub get had issues: ${pubGetResult.stderr}');
        }
      } catch (e) {
        print('⚠️  Could not run pub get: $e');
      }
    } else {
      // Pure Dart project
      try {
        print('📥 Running dart pub get...');
        final pubGetResult = await Process.run('dart', ['pub', 'get'],
            workingDirectory: dir.path);

        if (pubGetResult.exitCode == 0) {
          print('✅ Dependencies restored');
        } else {
          print('⚠️  pub get had issues: ${pubGetResult.stderr}');
        }
      } catch (e) {
        print('⚠️  Could not run dart pub get: $e');
      }
    }
  }

  print('\n🎉 Clean process completed for ${pubspecFiles.length} project(s)!');
}

Future<List<File>> _discoverPubspecs(Directory root) async {
  final pubspecs = <File>[];

  // 1. Checa se o diretório raiz possui pubspec.yaml
  final rootPubspec = File(p.join(root.path, 'pubspec.yaml'));
  if (rootPubspec.existsSync()) {
    pubspecs.add(rootPubspec);
  }

  // 2. Se o usuário estiver na HOME e não houver pubspec, não faça varredura no disco inteiro
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && p.canonicalize(root.path) == p.canonicalize(home)) {
    if (pubspecs.isEmpty) {
      print('⚠️ Você está no diretório raiz do usuário (~).');
      print('👉 Navegue até a pasta do seu projeto/workspace antes de executar o clean (ex: cd dev/meu_projeto).\n');
      return pubspecs;
    }
  }

  // 3. Varredura recursiva segura com proteção contra erros de permissão e profundidade máxima
  void scanDir(Directory dir, int depth) {
    if (depth > 4) return;
    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        final name = p.basename(entity.path);
        if (name.startsWith('.') && name != '.shepherd') continue;
        if (_excludedDirs.contains(name)) continue;

        if (entity is File && name == 'pubspec.yaml') {
          if (!pubspecs.any((f) => f.path == entity.path)) {
            pubspecs.add(entity);
          }
        } else if (entity is Directory) {
          scanDir(entity, depth + 1);
        }
      }
    } on FileSystemException catch (_) {
      // Ignora pastas protegidas pelo sistema operacional (ex: Fotos, Biblioteca macOS)
    } catch (_) {
      // Ignora outros erros de acesso
    }
  }

  scanDir(root, 0);
  return pubspecs;
}
