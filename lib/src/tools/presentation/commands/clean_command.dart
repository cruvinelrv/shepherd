import 'dart:io';
import 'package:path/path.dart' as p;

import '../../domain/services/workspace_manifest_service.dart';
import '../../../domains/domain/services/microfrontends_manifest_service.dart';
import '../../../i18n/i18n.dart';

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
  print(t('cl.start'));

  Directory root = Directory.current;
  final pubspecFiles = <File>[];

  // 1. Specific target (if passed as argument)
  String? targetArg;
  if (args.isNotEmpty && args.first != 'project') {
    targetArg = args.first.trim();
  }

  if (targetArg != null) {
    var targetDir = Directory(p.normalize(p.absolute(root.path, targetArg)));
    if (!targetDir.existsSync()) {
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && targetArg.startsWith('~')) {
        targetDir = Directory(p.normalize(targetArg.replaceFirst('~', home)));
      }
    }

    if (!targetDir.existsSync()) {
      // Check if targetArg matches a project in workspace manifest
      final manifest = WorkspaceManifest.tryLoad(root);
      if (manifest != null) {
        final match = manifest.projects.where((p) =>
            p.name.toLowerCase() == targetArg!.toLowerCase() ||
            p.id.toLowerCase() == targetArg.toLowerCase());
        if (match.isNotEmpty) {
          final matchedDir = Directory(
              p.normalize(p.join(manifest.rootDir.path, match.first.path)));
          if (matchedDir.existsSync()) {
            targetDir = matchedDir;
            print(t('cl.ws_project', {'name': match.first.name}));
          }
        }
      }
    }

    if (!targetDir.existsSync()) {
      // Check if targetArg matches a microfrontend in microfrontends manifest
      final mfList = MicrofrontendsManifestService.load(root);
      final mfBaseDir =
          MicrofrontendsManifestService.baseDirectory(root) ?? root;
      final match = mfList.where((m) =>
          m.name.toLowerCase() == targetArg!.toLowerCase());
      if (match.isNotEmpty) {
        final relPath =
            (match.first.path != null && match.first.path!.isNotEmpty)
                ? match.first.path!
                : match.first.name;
        final matchedDir = Directory(p.normalize(
            p.isAbsolute(relPath) ? relPath : p.join(mfBaseDir.path, relPath)));
        if (matchedDir.existsSync()) {
          targetDir = matchedDir;
          print(t('cl.mf_project', {'name': match.first.name}));
        }
      }
    }

    if (targetDir.existsSync()) {
      root = targetDir;
      print(t('cl.target', {'path': root.path}));
    } else {
      print(t('cl.target_missing', {'arg': targetArg}));
      exitCode = 1;
      return;
    }
  }

  final isProjectSpecific = args.isNotEmpty && args.first == 'project';

  if (isProjectSpecific) {
    // Clean only current project
    final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      pubspecFiles.add(pubspecFile);
      print(t('cl.current_only', {'path': root.path}));
    } else {
      print(t('cl.no_pubspec_here', {'path': root.path}));
      exitCode = 1;
      return;
    }
  } else {
    // 2. Try discovering via Microfrontends (.shepherd/microfrontends.yaml)
    final mfList = MicrofrontendsManifestService.load(root);
    final mfBaseDir = MicrofrontendsManifestService.baseDirectory(root);
    if (mfList.isNotEmpty && mfBaseDir != null) {
      print(t('cl.mf_manifest', {'n': mfList.length}));

      // Include container/host project if it has a pubspec.yaml
      final hostPubspec = File(p.join(mfBaseDir.path, 'pubspec.yaml'));
      if (hostPubspec.existsSync() &&
          !pubspecFiles.any((f) => f.path == hostPubspec.path)) {
        pubspecFiles.add(hostPubspec);
      }

      for (final mf in mfList) {
        final relPath =
            (mf.path != null && mf.path!.isNotEmpty) ? mf.path! : mf.name;
        final mfDir = Directory(p.normalize(
            p.isAbsolute(relPath) ? relPath : p.join(mfBaseDir.path, relPath)));
        final mfPubspec = File(p.join(mfDir.path, 'pubspec.yaml'));
        if (mfPubspec.existsSync() &&
            !pubspecFiles.any((f) => f.path == mfPubspec.path)) {
          pubspecFiles.add(mfPubspec);
        }
      }
    } else {
      // 3. Try discovering via Workspace (.shepherd/workspace.yaml)
      final manifest = WorkspaceManifest.tryLoad(root);
      if (manifest != null && manifest.projects.isNotEmpty) {
        print(t('cl.manifest',
            {'name': manifest.name, 'n': manifest.projects.length}));
        for (final proj in manifest.projects) {
          final projPubspec = File(p.normalize(
              p.join(manifest.rootDir.path, proj.path, 'pubspec.yaml')));
          if (projPubspec.existsSync() &&
              !pubspecFiles.any((f) => f.path == projPubspec.path)) {
            pubspecFiles.add(projPubspec);
          }
        }
      }
    }

    // 4. Ensure current directory project is included if it has a pubspec.yaml
    final rootPubspec = File(p.join(root.path, 'pubspec.yaml'));
    if (rootPubspec.existsSync() &&
        !pubspecFiles.any((f) => f.path == rootPubspec.path)) {
      pubspecFiles.insert(0, rootPubspec);
    }

    // 5. If no manifest exists or list is still empty, discover safely on disk
    if (pubspecFiles.isEmpty) {
      print(t('cl.searching'));
      pubspecFiles.addAll(await _discoverPubspecs(root));
    }

    if (pubspecFiles.isEmpty) {
      print(t('cl.none_found', {'path': root.path}));
      print(t('clean.navigate'));
      return;
    }

    print(t('cl.found', {'n': pubspecFiles.length}));
  }

  // Clean each project
  for (final pubspec in pubspecFiles) {
    final dir = pubspec.parent;
    final projectName = p.basename(dir.path);

    print('\n\x1b[1m${t('cl.cleaning', {
          'name': projectName,
          'path': dir.path
        })}\x1b[0m');

    // Remove pubspec.lock
    final pubspecLock = File(p.join(dir.path, 'pubspec.lock'));
    if (await pubspecLock.exists()) {
      try {
        await pubspecLock.delete();
        print(t('cl.rm_lock'));
      } catch (e) {
        print(t('cl.rm_lock_fail', {'e': e}));
      }
    }

    // Remove build directory
    final buildDir = Directory(p.join(dir.path, 'build'));
    if (await buildDir.exists()) {
      try {
        await buildDir.delete(recursive: true);
        print(t('cl.rm_build'));
      } catch (e) {
        print(t('cl.rm_build_fail', {'e': e}));
      }
    }

    // Remove .dart_tool directory
    final dartToolDir = Directory(p.join(dir.path, '.dart_tool'));
    if (await dartToolDir.exists()) {
      try {
        await dartToolDir.delete(recursive: true);
        print(t('cl.rm_dart_tool'));
      } catch (e) {
        print(t('cl.rm_dart_tool_fail', {'e': e}));
      }
    }

    // Check if it's a Flutter or pure Dart project
    bool isFlutter = false;
    try {
      final content = await pubspec.readAsString();
      isFlutter =
          content.contains('sdk: flutter') || content.contains('flutter:');
    } catch (_) {}

    if (isFlutter) {
      // Run flutter clean
      try {
        print(t('cl.flutter_clean'));
        final cleanResult =
            await Process.run('flutter', ['clean'], workingDirectory: dir.path);

        if (cleanResult.exitCode == 0) {
          print(t('cl.flutter_clean_ok'));
        } else {
          print(t('cl.flutter_clean_issues', {'e': cleanResult.stderr}));
        }
      } catch (e) {
        print(t('cl.flutter_clean_fail', {'e': e}));
      }

      // Run flutter pub get
      try {
        print(t('cl.flutter_get'));
        final pubGetResult = await Process.run('flutter', ['pub', 'get'],
            workingDirectory: dir.path);

        if (pubGetResult.exitCode == 0) {
          print(t('cl.deps_ok'));
        } else {
          print(t('cl.get_issues', {'e': pubGetResult.stderr}));
        }
      } catch (e) {
        print(t('cl.flutter_get_fail', {'e': e}));
      }
    } else {
      // Pure Dart project
      try {
        print(t('cl.dart_get'));
        final pubGetResult = await Process.run('dart', ['pub', 'get'],
            workingDirectory: dir.path);

        if (pubGetResult.exitCode == 0) {
          print(t('cl.deps_ok'));
        } else {
          print(t('cl.get_issues', {'e': pubGetResult.stderr}));
        }
      } catch (e) {
        print(t('cl.dart_get_fail', {'e': e}));
      }
    }
  }

  print('\n${t('cl.done', {'n': pubspecFiles.length})}');
}

Future<List<File>> _discoverPubspecs(Directory root) async {
  final pubspecs = <File>[];

  // 1. Check if the root directory contains a pubspec.yaml
  final rootPubspec = File(p.join(root.path, 'pubspec.yaml'));
  if (rootPubspec.existsSync()) {
    pubspecs.add(rootPubspec);
  }

  // 2. If the user is in HOME and no pubspec is found, do not scan the whole disk
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && p.canonicalize(root.path) == p.canonicalize(home)) {
    if (pubspecs.isEmpty) {
      print(t('clean.home1'));
      print(t('clean.home2'));
      return pubspecs;
    }
  }

  // 3. Safe recursive scan protected against permission errors and max depth
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
