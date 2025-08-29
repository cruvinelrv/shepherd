import 'package:shepherd/src/tools/domain/usecases/changelog_usecase.dart';
import 'dart:io';
import 'package:yaml/yaml.dart';

class ChangelogController {
  final ChangelogUseCase useCase;
  ChangelogController(this.useCase);

  Future<void> run() async {
    final dir = Directory.current.path;
    String branch = '';
    try {
      final result =
          await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
      if (result.exitCode == 0) {
        branch = result.stdout.toString().trim();
      }
    } catch (_) {}
    final envFile = File('$dir/.shepherd/environments.yaml');
    final envBranches = <String>[];
    if (envFile.existsSync()) {
      final content = envFile.readAsStringSync();
      final map = loadYaml(content);
      if (map is Map) {
        envBranches.addAll(map.values.map((v) => v.toString()));
      }
    }
    if (envBranches.contains(branch)) {
      print(
          'CHANGELOG.md was NOT updated: current branch "$branch" is an environment branch.');
      return;
    }
    await useCase.updateChangelog();
  }
}
