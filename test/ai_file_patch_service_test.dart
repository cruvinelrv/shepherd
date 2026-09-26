import 'dart:io';
import 'package:test/test.dart';
import 'package:shepherd/src/tools/domain/entities/ai_file_action_entity.dart';
import 'package:shepherd/src/tools/domain/services/ai_file_patch_service.dart';

void main() {
  group('AiFilePatchService', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('shepherd_patch_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('extracts file action from markdown code fences with // FILE: path', () {
      const response = '''
Aqui está a alteração necessária:

```dart
// FILE: lib/src/example.dart
class Example {
  final String title;
  const Example(this.title);
}
```

Isso resolve o problema.
''';

      final actions = AiFilePatchService.extractActions(response);
      expect(actions.length, equals(1));
      expect(actions.first.path, equals('lib/src/example.dart'));
      expect(actions.first.newContent, contains('class Example'));
    });

    test('applies file creation and writes content safely', () {
      const action = AiFileActionEntity(
        path: 'lib/new_feature.dart',
        actionType: AiFileActionType.create,
        newContent: 'void runFeature() {}',
      );

      final success = AiFilePatchService.applyAction(action, basePath: tempDir.path);
      expect(success, isTrue);

      final createdFile = File('${tempDir.path}/lib/new_feature.dart');
      expect(createdFile.existsSync(), isTrue);
      expect(createdFile.readAsStringSync(), equals('void runFeature() {}'));
    });

    test('rejects path traversal attempts that escape the workspace', () {
      const unsafeAction = AiFileActionEntity(
        path: '../../etc/dangerous.txt',
        actionType: AiFileActionType.create,
        newContent: 'malicious',
      );

      final success = AiFilePatchService.applyAction(unsafeAction, basePath: tempDir.path);
      expect(success, isFalse);
    });

    test('formats colored diff output properly', () {
      final diff = AiFilePatchService.formatColoredDiff(
        filePath: 'lib/demo.dart',
        originalContent: 'line 1\nold line 2\nline 3',
        newContent: 'line 1\nnew line 2\nline 3',
      );

      expect(diff, contains('--- lib/demo.dart'));
      expect(diff, contains('- old line 2'));
      expect(diff, contains('+ new line 2'));
    });
  });
}
