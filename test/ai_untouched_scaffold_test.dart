import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shepherd/src/tools/domain/services/ai_settings_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('isUntouchedScaffold', () {
    test('the specs template the scaffold writes', () {
      expect(
        isUntouchedScaffold('''# Shepherd Project Specifications
specs:
  project: "pequena-floresta"
  version: "1.0.0"
  architecture: "DDD"
  requirements: []
'''),
        isTrue,
      );
    });

    test('empty collections and comment-only files', () {
      expect(isUntouchedScaffold('# Shepherd Workspace Skills\nskills: []\n'),
          isTrue);
      expect(isUntouchedScaffold('domains: []'), isTrue);
      expect(isUntouchedScaffold('# only a comment'), isTrue);
    });

    test('anything the user changed or added counts as content', () {
      expect(
        isUntouchedScaffold('''specs:
  project: "x"
  version: "1.0.0"
  architecture: "Hexagonal"
  requirements: []
'''),
        isFalse,
      );
      expect(
        isUntouchedScaffold('''specs:
  project: "x"
  version: "1.0.0"
  architecture: "DDD"
  requirements:
    - Login
'''),
        isFalse,
      );
      expect(isUntouchedScaffold('skills:\n  - name: a'), isFalse);
    });
  });

  test('the AI context leaves out the untouched specs template', () {
    final previous = Directory.current;
    final tmp = Directory.systemTemp.createTempSync('ctx');
    addTearDown(() {
      Directory.current = previous;
      tmp.deleteSync(recursive: true);
    });
    Directory.current = tmp;
    File(p.join(tmp.path, '.shepherd', 'specs.yaml'))
      ..createSync(recursive: true)
      ..writeAsStringSync(
          'specs:\n  project: "x"\n  version: "1.0.0"\n  architecture: "DDD"\n  requirements: []\n');
    File(p.join(tmp.path, '.shepherd', 'project.yaml'))
        .writeAsStringSync('name: "Pequena Floresta"\n');

    final text = readAiWorkspaceContext(includeWorkspace: false);
    expect(text, isNot(contains('DDD')));
    expect(text, isNot(contains('specs.yaml')));
    expect(text, contains('Pequena Floresta')); // real content still there
  });
}
