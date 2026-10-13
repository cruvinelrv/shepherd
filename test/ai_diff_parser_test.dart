import 'package:shepherd/src/tools/domain/services/ai_diff_parser.dart';
import 'package:shepherd/src/tools/domain/services/ai_file_patch_service.dart';
import 'package:test/test.dart';

const _config = "class C {\n  static Map<String, String> config = {\n"
    "    'broadcast': 'Broadcast',\n    'example': 'Example',\n  };\n}\n";

AiDiffResult _parse(String diff, Map<String, String> files) =>
    AiDiffParser.parse('```diff\n$diff```\n', readOriginal: (p) => files[p]);

void main() {
  group('AiDiffParser', () {
    test('applies a diff that matches, ignoring wrong line numbers', () {
      final r = _parse('''--- a/lib/c.dart
+++ b/lib/c.dart
@@ -90,3 +90,4 @@
   static Map<String, String> config = {
+    'benup': 'Benup',
     'broadcast': 'Broadcast',
''', {'lib/c.dart': _config});
      expect(r.failures, isEmpty);
      expect(r.actions.single.path, 'lib/c.dart');
      expect(r.actions.single.newContent,
          contains("config = {\n    'benup': 'Benup',\n    'broadcast'"));
      expect(r.actions.single.newContent, endsWith('}\n'));
    });

    test('discards a diff whose context is not in the real file', () {
      final r = _parse('''--- a/lib/c.dart
+++ b/lib/c.dart
@@ -1,2 +1,3 @@
 nothing like this exists
+added
''', {'lib/c.dart': _config});
      expect(r.actions, isEmpty);
      expect(r.failures.single.path, 'lib/c.dart');
    });

    test('discards a modification of a file that does not exist', () {
      final r = _parse('''--- a/mio/white.dart
+++ b/mio/white.dart
@@ -3,6 +3,7 @@
 class A {
+  int x;
''', {});
      expect(r.actions, isEmpty);
      expect(r.failures, hasLength(1));
    });

    test('creates a file from a /dev/null diff', () {
      final r = _parse('''--- /dev/null
+++ b/lib/novo.dart
@@ -0,0 +1,2 @@
+void a() {}
+void b() {}
''', {});
      expect(r.failures, isEmpty);
      expect(r.actions.single.newContent, 'void a() {}\nvoid b() {}\n');
    });

    test('refuses an ambiguous match', () {
      final r = _parse('''--- a/x.txt
+++ b/x.txt
@@ -50,1 +50,2 @@
 same
+extra
''', {'x.txt': 'same\nother\nsame\n'});
      expect(r.actions, isEmpty);
      expect(r.failures, hasLength(1));
    });

    test('never applies a deletion', () {
      final r = _parse('''--- a/x.txt
+++ /dev/null
@@ -1,1 +0,0 @@
-same
''', {'x.txt': 'same\n'});
      expect(r.actions, isEmpty);
    });
  });

  group('AiFilePatchService.extract', () {
    test('warns about code that is not in the FILE format', () {
      final e = AiFilePatchService.extract(
          'Aqui:\n```dart\nvoid main() {}\nvoid b() {}\nvoid c() {}\n```\n');
      expect(e.actions, isEmpty);
      expect(e.unrecognizedCode, isTrue);
      expect(e.warnings.single, contains('// FILE:'));
    });

    test('no warning for plain prose', () {
      final e = AiFilePatchService.extract('Tudo certo, nada a alterar.');
      expect(e.warnings, isEmpty);
    });

    test('reports a diff that does not apply, without the generic warning', () {
      final e = AiFilePatchService.extract(
          '```diff\n--- a/nao/existe.dart\n+++ b/nao/existe.dart\n@@ -1,1 +1,2 @@\n a\n+b\n```\n',
          readOriginal: (_) => null);
      expect(e.actions, isEmpty);
      expect(e.unrecognizedCode, isFalse);
      expect(e.warnings.single, contains('nao/existe.dart'));
    });
  });
}
