import 'dart:io';
import 'package:yaml_writer/yaml_writer.dart';

import '../../../domains/data/datasources/local/domains_database.dart';

class ExportYamlUseCase {
  final DomainsDatabase domainsDb;
  ExportYamlUseCase(this.domainsDb);

  Future<void> exportYaml() async {
    final domains = await domainsDb.getAllDomainHealths();
    final db = await domainsDb.database;
    final List<Map<String, dynamic>> yamlDomains = [];
    for (final domain in domains) {
      final ownerRows = await db.rawQuery('''
        SELECT p.first_name, p.last_name, p.email, p.type, p.github_username FROM domain_owners o
        JOIN persons p ON o.person_id = p.id
        WHERE o.domain_name = ? AND o.project_path = ?
      ''', [domain.domainName, domainsDb.projectPath]);
      yamlDomains.add({
        'name': domain.domainName,
        'owners': ownerRows
            .map((o) => {
                  'first_name': o['first_name'],
                  'last_name': o['last_name'],
                  'email': o['email'],
                  'type': o['type'],
                  'github_username': o['github_username'],
                })
            .toList(),
        'warnings': domain.warnings,
      });
    }
    final yamlMap = {'domains': yamlDomains};
    final writer = YamlWriter();
    final yamlString = writer.write(yamlMap);
    final yamlFile =
        File('${domainsDb.projectPath}/dev_tools/shepherd/domains.yaml');
    await yamlFile.writeAsString(yamlString);
  }
}
