import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

import '../../../../config/data/datasources/local/config_database.dart';
import '../../../../domains/data/datasources/local/domains_database.dart';
import '../../../../menu/presentation/cli/user_active_utils.dart';
import '../../../../sync/domain/usecases/export_yaml_usecase.dart';
import '../../../../tools/domain/services/workspace_scaffold_service.dart';

/// Everything the quick init decided.
class QuickInitPlan {
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String? githubUsername;

  /// `github`, `azure` or null (later).
  final String? repoType;
  final String trunk;

  const QuickInitPlan({
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.trunk,
    this.githubUsername,
    this.repoType,
  });
}

String _newId() {
  final rand = Random.secure();
  return List.generate(32, (_) => rand.nextInt(16).toRadixString(16)).join();
}

/// Writes the standard project into [dir]: the YAML files, the domain and its
/// owner in the database, and the active user. Nothing is asked here.
Future<void> writeQuickInit(QuickInitPlan plan, Directory dir) async {
  // Some helpers (active user, domains.yaml) write relative to the working directory.
  Directory.current = dir.path;
  String at(String rel) => p.join(dir.path, rel);
  Directory(at('.shepherd')).createSync(recursive: true);
  Directory(at('devops')).createSync(recursive: true);

  File(at('.shepherd/project.yaml')).writeAsStringSync(YamlWriter()
      .write({'id': _newId(), 'name': plan.name, 'init_mode': 'full'}));
  // Trunk based development: one environment, production, on the trunk.
  File(at('.shepherd/environments.yaml'))
      .writeAsStringSync(YamlWriter().write({'PRD': plan.trunk}));
  File(at('.shepherd/workspace.yaml')).writeAsStringSync('''workspace:
  name: ${_quote(plan.name)}
  version: "1.0.0"
  team_members: []
  squads:
    - name: "MAIN"
      members: []
  domains: []
''');

  final configFile = File(at('.shepherd/config.yaml'));
  final config = <String, dynamic>{};
  if (configFile.existsSync()) {
    final loaded = loadYaml(configFile.readAsStringSync());
    if (loaded is YamlMap) config.addAll(Map<String, dynamic>.from(loaded));
  }
  config.remove('project_id'); // only `shepherd login` links a Union project
  if (plan.repoType != null) config['repoType'] = plan.repoType;
  config['pullRequestEnabled'] = plan.repoType != null;
  configFile.writeAsStringSync(YamlWriter().write(config));

  // The rest of the standard files, only the ones still missing.
  WorkspaceScaffoldService.ensureShepherdFiles(basePath: dir.path);

  final configDb = ConfigDatabase(dir.path);
  final domainsDb = DomainsDatabase(dir.path);
  try {
    final personId = await configDb.insertPerson(
      firstName: plan.firstName,
      lastName: plan.lastName,
      email: plan.email,
      type: 'developer',
      githubUsername: plan.githubUsername,
    );
    await domainsDb.insertDomain(
      domainName: plan.name,
      score: 0.0,
      commits: 0,
      days: 0,
      warnings: '',
      personIds: [personId],
      projectPath: dir.path,
    );
    final person = await configDb.getPersonById(personId);
    if (person != null) await writeActiveUser(person);
    await ExportYamlUseCase(domainsDb).exportYaml();
  } finally {
    await configDb.close();
    await domainsDb.close();
  }
}

String _quote(String s) =>
    '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

/// True when [dir] already holds a Shepherd project (a project.yaml with an id).
bool isInitialized(Directory dir) {
  final f = File(p.join(dir.path, '.shepherd', 'project.yaml'));
  if (!f.existsSync()) return false;
  try {
    final y = loadYaml(f.readAsStringSync());
    return y is YamlMap && y['id'] != null && y['name'] != null;
  } catch (_) {
    return false;
  }
}
