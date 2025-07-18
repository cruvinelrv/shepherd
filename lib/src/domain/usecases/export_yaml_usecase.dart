import 'dart:io';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:yaml_writer/yaml_writer.dart';

class ExportYamlUseCase {
  final ShepherdDatabase shepherdDb;
  ExportYamlUseCase(this.shepherdDb);

  Future<void> exportYaml() async {
    final domains = await shepherdDb.getAllDomainHealths();
    final db = await shepherdDb.database;
    final List<Map<String, dynamic>> yamlDomains = [];
    for (final domain in domains) {
      final ownerRows = await db.rawQuery('''
        SELECT p.first_name, p.last_name, p.type FROM domain_owners o
        JOIN persons p ON o.person_id = p.id
        WHERE o.domain_name = ? AND o.project_path = ?
      ''', [domain.domainName, shepherdDb.projectPath]);
      yamlDomains.add({
        'name': domain.domainName,
        'owners': ownerRows
            .map((o) => {
                  'first_name': o['first_name'],
                  'last_name': o['last_name'],
                  'type': o['type'],
                })
            .toList(),
        'warnings': domain.warnings,
      });
    }
    final yamlMap = {'domains': yamlDomains};
    final writer = YAMLWriter();
    final yamlString = writer.write(yamlMap);
    final yamlFile = File('${shepherdDb.projectPath}/devops/domains.yaml');
    await yamlFile.writeAsString(yamlString);
  }
}
