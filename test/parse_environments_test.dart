import 'package:shepherd/src/tools/presentation/commands/login_command.dart';
import 'package:test/test.dart';

void main() {
  group('parseLocalEnvironments', () {
    test('returns empty list for null or empty input', () {
      expect(parseLocalEnvironments(null), isEmpty);
      expect(parseLocalEnvironments(''), isEmpty);
      expect(parseLocalEnvironments('   '), isEmpty);
    });

    test('ignores environments: [] without emitting environments as name', () {
      const yaml = '''
environments: []
''';
      final result = parseLocalEnvironments(yaml);
      expect(result, isEmpty);
    });

    test('parses flat key-value environment mappings correctly', () {
      const yaml = '''
dev: develop
staging: release
prod: main
''';
      final result = parseLocalEnvironments(yaml);
      expect(result, hasLength(3));
      expect(result[0], equals({'name': 'dev', 'branch': 'develop'}));
      expect(result[1], equals({'name': 'staging', 'branch': 'release'}));
      expect(result[2], equals({'name': 'prod', 'branch': 'main'}));
    });

    test('parses list under environments key', () {
      const yaml = '''
environments:
  - name: dev
    branch: develop
  - name: prod
    branch: main
''';
      final result = parseLocalEnvironments(yaml);
      expect(result, hasLength(2));
      expect(result[0], equals({'name': 'dev', 'branch': 'develop'}));
      expect(result[1], equals({'name': 'prod', 'branch': 'main'}));
    });

    test('parses map under environments key', () {
      const yaml = '''
environments:
  dev: develop
  prod: main
''';
      final result = parseLocalEnvironments(yaml);
      expect(result, hasLength(2));
      expect(result[0], equals({'name': 'dev', 'branch': 'develop'}));
      expect(result[1], equals({'name': 'prod', 'branch': 'main'}));
    });
  });
}
