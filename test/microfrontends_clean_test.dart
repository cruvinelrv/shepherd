import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shepherd/src/domains/domain/services/microfrontends_manifest_service.dart';
import 'package:shepherd/src/tools/presentation/commands/clean_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('clean_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('MicrofrontendsManifestService finds and loads microfrontends.yaml up tree', () {
    final shepherdDir = Directory(p.join(tempDir.path, '.shepherd'))..createSync();
    final mfYaml = File(p.join(shepherdDir.path, 'microfrontends.yaml'));
    mfYaml.writeAsStringSync('''
microfrontends:
  - name: mf_auth
    path: packages/mf_auth
  - name: mf_home
    path: packages/mf_home
''');

    final subDir = Directory(p.join(tempDir.path, 'lib', 'src'))..createSync(recursive: true);

    final file = MicrofrontendsManifestService.findManifestFile(subDir);
    expect(file, isNotNull);
    expect(file!.path, mfYaml.path);

    final baseDir = MicrofrontendsManifestService.baseDirectory(subDir);
    expect(baseDir, isNotNull);
    expect(p.canonicalize(baseDir!.path), p.canonicalize(tempDir.path));

    final list = MicrofrontendsManifestService.load(subDir);
    expect(list.length, 2);
    expect(list[0].name, 'mf_auth');
    expect(list[0].path, 'packages/mf_auth');
    expect(list[1].name, 'mf_home');
    expect(list[1].path, 'packages/mf_home');
  });

  test('runCleanCommand cleans projects listed in microfrontends.yaml', () async {
    final shepherdDir = Directory(p.join(tempDir.path, '.shepherd'))..createSync();
    File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('name: root_app\n');

    final mf1Dir = Directory(p.join(tempDir.path, 'packages', 'mf1'))..createSync(recursive: true);
    File(p.join(mf1Dir.path, 'pubspec.yaml')).writeAsStringSync('name: mf1\n');
    File(p.join(mf1Dir.path, 'pubspec.lock')).writeAsStringSync('# lock\n');

    final mf2Dir = Directory(p.join(tempDir.path, 'packages', 'mf2'))..createSync(recursive: true);
    File(p.join(mf2Dir.path, 'pubspec.yaml')).writeAsStringSync('name: mf2\n');
    File(p.join(mf2Dir.path, 'pubspec.lock')).writeAsStringSync('# lock\n');

    File(p.join(shepherdDir.path, 'microfrontends.yaml')).writeAsStringSync('''
microfrontends:
  - name: mf1
    path: packages/mf1
  - name: mf2
    path: packages/mf2
''');

    final prevDir = Directory.current;
    try {
      Directory.current = tempDir;
      await runCleanCommand([]);
    } finally {
      Directory.current = prevDir;
    }

    // pubspec.lock should have been deleted by clean
    expect(File(p.join(mf1Dir.path, 'pubspec.lock')).existsSync(), isFalse);
    expect(File(p.join(mf2Dir.path, 'pubspec.lock')).existsSync(), isFalse);
  });
}
