import 'dart:io';

/// Clean command implementation
Future<void> runCleanCommand(List<String> args) async {
  print('🧹 Starting Shepherd Clean...\n');

  final root = Directory.current;
  final pubspecFiles = <File>[];

  // Check if there's a specific target
  final isProjectSpecific = args.isNotEmpty && args.first == 'project';

  if (isProjectSpecific) {
    // Clean only current project
    final pubspecFile = File('${root.path}/pubspec.yaml');
    if (await pubspecFile.exists()) {
      pubspecFiles.add(pubspecFile);
      print('📍 Cleaning current project only...');
    } else {
      print('❌ No pubspec.yaml found in the current directory.');
      exit(1);
    }
  } else {
    // Clean all projects/microfrontends recursively
    print('🔍 Searching for all pubspec.yaml files...');
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('pubspec.yaml')) {
        pubspecFiles.add(entity);
      }
    }

    if (pubspecFiles.isEmpty) {
      print('❌ No pubspec.yaml files found in the project.');
      exit(1);
    }

    print('📦 Found ${pubspecFiles.length} project(s) to clean');
  }

  // Clean each project
  for (final pubspec in pubspecFiles) {
    final dir = pubspec.parent;
    final projectName = dir.path.split('/').last;

    print('\n--- 🧽 Cleaning: \x1b[1m$projectName (${dir.path})\x1b[0m ---');

    // Remove pubspec.lock
    final pubspecLock = File('${dir.path}/pubspec.lock');
    if (await pubspecLock.exists()) {
      await pubspecLock.delete();
      print('🗑️  Removed pubspec.lock');
    }

    // Remove build directory
    final buildDir = Directory('${dir.path}/build');
    if (await buildDir.exists()) {
      await buildDir.delete(recursive: true);
      print('🗑️  Removed build/ directory');
    }

    // Remove .dart_tool directory
    final dartToolDir = Directory('${dir.path}/.dart_tool');
    if (await dartToolDir.exists()) {
      await dartToolDir.delete(recursive: true);
      print('🗑️  Removed .dart_tool/ directory');
    }

    // Run flutter clean
    try {
      print('🔧 Running flutter clean...');
      final cleanResult = await Process.run('flutter', ['clean'], workingDirectory: dir.path);

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
      final pubGetResult = await Process.run('flutter', ['pub', 'get'], workingDirectory: dir.path);

      if (pubGetResult.exitCode == 0) {
        print('✅ Dependencies restored');
      } else {
        print('⚠️  pub get had issues: ${pubGetResult.stderr}');
      }
    } catch (e) {
      print('⚠️  Could not run pub get: $e');
    }
  }

  print('\n🎉 Clean process completed for ${pubspecFiles.length} project(s)!');
}
