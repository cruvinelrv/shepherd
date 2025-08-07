import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// Adds a new domain to domains.yaml if it does not already exist.
/// Returns true if the domain was created, false if it already existed.
/// Adds a new domain to domains.yaml if it does not already exist.
/// If promptIfMissing is true, asks the user before creating a new domain.
/// Returns true if the domain was created, false if already existed, null if user refused to create.
Future<bool?> addDomainController(String domainName, {bool promptIfMissing = false}) async {
  final file = File('dev_tools/shepherd/domains.yaml');
  final yamlContent = file.existsSync() ? file.readAsStringSync() : '';
  final yaml = yamlContent.isNotEmpty ? loadYaml(yamlContent) : {};
  final domains = (yaml['domains'] as List?)?.toList() ?? [];
  final exists = domains
      .any((d) => d is Map && (d['name'] as String?)?.toLowerCase() == domainName.toLowerCase());
  if (exists) {
    return false;
  }
  if (promptIfMissing) {
    stdout.write('Domain "$domainName" does not exist. Do you want to create it? (y/N): ');
    final resp = stdin.readLineSync()?.trim().toLowerCase();
    if (resp != 'y' && resp != 'yes' && resp != 's' && resp != 'sim') {
      return null;
    }
  }
  domains.add({'name': domainName, 'owners': [], 'warnings': []});
  final updated = Map<String, dynamic>.from(yaml is YamlMap ? Map<String, dynamic>.from(yaml) : {});
  updated['domains'] = domains;
  final writer = YamlWriter();
  file.writeAsStringSync(writer.write(updated), mode: FileMode.write);
  return true;
}
