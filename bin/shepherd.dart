import 'dart:io';
import 'package:args/args.dart';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/domain/services/analysis_service.dart';
import 'package:shepherd/src/domain/services/config_service.dart';
import 'package:shepherd/src/domain/services/domain_info_service.dart';
import 'package:shepherd/src/domain/entities/domain_health_entity.dart';
import 'package:yaml_writer/yaml_writer.dart';

import 'package:shepherd/src/domain/services/changelog_service.dart';

// ...outras funções...

Future<void> _runChangelogCommand() async {
  try {
    final service = ChangelogService();
    await service.updateChangelog();
    print('CHANGELOG.md atualizado com sucesso!');
  } catch (e) {
    print('Erro ao atualizar o changelog: $e');
    exit(1);
  }
}

Future<void> _runExportYamlCommand() async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final domains = await shepherdDb.getAllDomainHealths();
  final db = await shepherdDb.database;

  final List<Map<String, dynamic>> yamlDomains = [];
  for (final domain in domains) {
    // Buscar owners desse domínio
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
  final yamlFile = File('$projectPath/devops/domains.yaml');
  await yamlFile.writeAsString(yamlString);
  await shepherdDb.close();
  print('Exportação concluída para domains.yaml!');
}

Future<void> _runDeleteCommand(String domainName) async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final configService = ConfigService(shepherdDb);
  await configService.removeDomain(domainName);
  await shepherdDb.close();
  print('Domínio "$domainName" removido do projeto.');
}

Future<void> _runAddOwnerCommand(String domainName) async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);

  // Verifica se o domínio existe
  final domains = await shepherdDb.getAllDomainHealths();
  DomainHealthEntity? domain;
  try {
    domain = domains.firstWhere((d) => d.domainName == domainName);
  } catch (_) {
    domain = null;
  }
  if (domain == null) {
    print('Domínio "$domainName" não encontrado.');
    await shepherdDb.close();
    return;
  }

  // Busca owners atuais
  final currentOwners = await shepherdDb.database.then((dbInst) => dbInst.rawQuery('''
    SELECT p.id, p.first_name, p.last_name, p.type FROM domain_owners o
    JOIN persons p ON o.person_id = p.id
    WHERE o.domain_name = ? AND o.project_path = ?
  ''', [domainName, shepherdDb.projectPath]));
  final currentOwnerIds = currentOwners.map((o) => o['id'] as int).toSet();

  print('Owners atuais do domínio "$domainName":');
  if (currentOwners.isEmpty) {
    print('  (nenhum)');
  } else {
    for (final o in currentOwners) {
      print('  - ${o['first_name']} ${o['last_name']} (${o['type']})');
    }
  }

  // Listar pessoas já cadastradas
  final persons = await shepherdDb.getAllPersons();
  if (persons.isNotEmpty) {
    print('Pessoas já cadastradas:');
    for (var i = 0; i < persons.length; i++) {
      final p = persons[i];
      print('  [${i + 1}] ${p['first_name']} ${p['last_name']} (${p['type']})');
    }
  } else {
    print('Nenhuma pessoa cadastrada ainda.');
  }

  int? personIdToAdd;
  while (personIdToAdd == null) {
    stdout
        .write('Digite o número da pessoa para adicionar como owner, ou "n" para cadastrar nova: ');
    final input = stdin.readLineSync();
    if (input == null || input.trim().isEmpty) {
      print('Operação cancelada.');
      await shepherdDb.close();
      return;
    }
    if (input.trim().toLowerCase() == 'n') {
      // Cadastro de nova pessoa
      stdout.write('Primeiro nome: ');
      final firstName = stdin.readLineSync()?.trim() ?? '';
      stdout.write('Sobrenome: ');
      final lastName = stdin.readLineSync()?.trim() ?? '';
      String? type;
      while (type == null || !['administrator', 'developer', 'lead_domain'].contains(type)) {
        stdout.write('Tipo (administrator, developer, lead_domain): ');
        type = stdin.readLineSync()?.trim();
      }
      final newId =
          await shepherdDb.insertPerson(firstName: firstName, lastName: lastName, type: type);
      personIdToAdd = newId;
      print('Pessoa cadastrada!');
    } else {
      final idx = int.tryParse(input.trim());
      if (idx != null && idx > 0 && idx <= persons.length) {
        final pid = persons[idx - 1]['id'] as int;
        if (currentOwnerIds.contains(pid)) {
          print('Essa pessoa já é owner deste domínio.');
        } else {
          personIdToAdd = pid;
        }
      } else {
        print('Entrada inválida.');
      }
    }
  }

  // Adiciona o novo owner
  await shepherdDb.database.then((dbInst) => dbInst.insert('domain_owners', {
        'domain_name': domainName,
        'project_path': shepherdDb.projectPath,
        'person_id': personIdToAdd,
      }));
  print('Pessoa adicionada como owner do domínio "$domainName"!');
  await shepherdDb.close();
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('analyze')
    ..addCommand('clean')
    ..addCommand('config')
    ..addCommand('list')
    ..addCommand('delete')
    ..addCommand('add-owner')
    ..addCommand('export-yaml')
    ..addCommand('changelog')
    ..addCommand('help');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    print(e.message);
    print('Uso: dart run shepherd <comando> [opções]');
    print(parser.usage);
    exit(1);
  }
  final command = argResults.command;

  if (command == null) {
    print('Nenhum comando especificado.');
    print('Uso: dart run shepherd <comando> [opções]');
    print(parser.usage);
    exit(1);
  }

  switch (command.name) {
    case 'analyze':
      await _runAnalyzeCommand();
      break;
    case 'clean':
      await _runCleanCommand(command.arguments);
      break;
    case 'config':
      await _runConfigCommand();
      break;
    case 'list':
      await _runListCommand();
      break;
    case 'delete':
      if (command.arguments.isEmpty) {
        print('Uso: dart run shepherd delete <dominio>');
        exit(1);
      }
      await _runDeleteCommand(command.arguments.first);
      break;
    case 'add-owner':
      if (command.arguments.isEmpty) {
        print('Uso: dart run shepherd add-owner <dominio>');
        exit(1);
      }
      await _runAddOwnerCommand(command.arguments.first);
      break;
    case 'export-yaml':
      await _runExportYamlCommand();
      break;
    case 'changelog':
      await _runChangelogCommand();
      break;
    case 'help':
      _printHelp();
      break;
  }
}

void _printHelp() {
  print('''
Shepherd CLI - Comandos disponíveis:

  analyze              Analisa os domínios do projeto atual.
  clean                Limpa todos os projetos (ou use "project" para limpar só o atual).
  config               Configura e cadastra domínios no projeto.
  list                 Lista todos os domínios cadastrados no projeto.
  delete <dominio>     Remove um domínio específico do projeto.

  add-owner <dominio>  Adiciona uma nova pessoa como owner de um domínio já existente.
  export-yaml          Exporta todos os domínios e owners para o arquivo devops/domains.yaml.
  changelog            Atualiza o CHANGELOG.md do projeto.
  help                 Exibe este menu de ajuda.

Exemplo de uso:
  dart run shepherd analyze
  dart run shepherd clean
  dart run shepherd clean project
  dart run shepherd config
  dart run shepherd list
  dart run shepherd delete auth_domain
  dart run shepherd changelog
''');
}

Future<void> _runListCommand() async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final infoService = DomainInfoService(shepherdDb);
  final domains = await infoService.listDomains();
  if (domains.isEmpty) {
    await shepherdDb.close();
    print('Nenhum domínio cadastrado.');
    return;
  }
  print('Domínios cadastrados:');
  for (final domain in domains) {
    // Buscar owners detalhados
    final db = shepherdDb;
    final ownerRows = await db.database.then((dbInst) => dbInst.rawQuery('''
      SELECT p.first_name, p.last_name, p.type FROM domain_owners o
      JOIN persons p ON o.person_id = p.id
      WHERE o.domain_name = ? AND o.project_path = ?
    ''', [domain.domainName, db.projectPath]));
    String owners;
    if (ownerRows.isEmpty) {
      owners = '';
    } else {
      owners =
          ' (owners: ${ownerRows.map((o) => '${o['first_name']} ${o['last_name']} [${o['type']}]').join(', ')})';
    }
    print('- ${domain.domainName}$owners');
  }
  await shepherdDb.close();
}

Future<void> _runConfigCommand() async {
  final projectPath = Directory.current.path;
  final shepherdDb = ShepherdDatabase(projectPath);
  final configService = ConfigService(shepherdDb);

  stdout.write(
      'Digite os domínios separados por vírgula (ex: auth_domain,user_domain,product_domain): ');
  final input = stdin.readLineSync();
  if (input == null || input.trim().isEmpty) {
    print('Nenhum domínio informado.');
    exit(1);
  }
  final domains = input.split(',').map((d) => d.trim()).where((d) => d.isNotEmpty).toList();
  if (domains.isEmpty) {
    print('Nenhum domínio válido informado.');
    exit(1);
  }

  for (final domain in domains) {
    print('\nConfiguração de owners para o domínio "$domain":');
    final personIds = <int>[];
    while (true) {
      // Listar pessoas já cadastradas
      final persons = await shepherdDb.getAllPersons();
      if (persons.isNotEmpty) {
        print('Pessoas já cadastradas:');
        for (var i = 0; i < persons.length; i++) {
          final p = persons[i];
          print('  [${i + 1}] ${p['first_name']} ${p['last_name']} (${p['type']})');
        }
      } else {
        print('Nenhuma pessoa cadastrada ainda.');
      }
      stdout.write(
          'Digite o número da pessoa para adicionar como owner, ou "n" para cadastrar nova, ou pressione Enter para finalizar: ');
      final input = stdin.readLineSync();
      if (input == null || input.trim().isEmpty) break;
      if (input.trim().toLowerCase() == 'n') {
        // Cadastro de nova pessoa
        stdout.write('Primeiro nome: ');
        final firstName = stdin.readLineSync()?.trim() ?? '';
        stdout.write('Sobrenome: ');
        final lastName = stdin.readLineSync()?.trim() ?? '';
        String? type;
        while (type == null || !['administrator', 'developer', 'lead_domain'].contains(type)) {
          stdout.write('Tipo (administrator, developer, lead_domain): ');
          type = stdin.readLineSync()?.trim();
        }
        final newId =
            await shepherdDb.insertPerson(firstName: firstName, lastName: lastName, type: type);
        personIds.add(newId);
        print('Pessoa cadastrada e adicionada como owner!');
      } else {
        final persons = await shepherdDb.getAllPersons();
        final idx = int.tryParse(input.trim());
        if (idx != null && idx > 0 && idx <= persons.length) {
          final personId = persons[idx - 1]['id'] as int;
          if (!personIds.contains(personId)) {
            personIds.add(personId);
            print('Pessoa adicionada como owner!');
          } else {
            print('Pessoa já adicionada.');
          }
        } else {
          print('Entrada inválida.');
        }
      }
    }
    try {
      await configService.addDomain(domain, personIds);
      // Exibe nomes dos owners cadastrados
      final owners = await shepherdDb.getAllPersons();
      final ownersStr = personIds.isEmpty
          ? '(nenhum informado)'
          : personIds.map((id) {
              final p = owners.firstWhere((p) => p['id'] == id,
                  orElse: () => {'first_name': 'ID $id', 'last_name': ''});
              return '${p['first_name']} ${p['last_name']}';
            }).join(", ");
      print('Domínio "$domain" cadastrado na base de dados com proprietários: $ownersStr!');
    } catch (e) {
      print('Erro ao cadastrar domínio "$domain": $e');
    }
  }
  await shepherdDb.close();
  print('Configuração de domínios concluída!');
}

Future<void> _runCleanCommand(List<String> args) async {
  final onlyCurrent = args.isNotEmpty && args.first == 'project';
  final root = Directory.current;
  final pubspecFiles = <File>[];

  if (onlyCurrent) {
    final pubspec = File('${root.path}/pubspec.yaml');
    if (await pubspec.exists()) {
      pubspecFiles.add(pubspec);
    } else {
      print('Nenhum pubspec.yaml encontrado no diretório atual.');
      exit(1);
    }
  } else {
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('pubspec.yaml')) {
        pubspecFiles.add(entity);
      }
    }
    if (pubspecFiles.isEmpty) {
      print('Nenhum pubspec.yaml encontrado no projeto.');
      exit(1);
    }
  }

  for (final pubspec in pubspecFiles) {
    final dir = pubspec.parent;
    print('\n--- Limpando: ${dir.path} ---');
    final pubspecLock = File('${dir.path}/pubspec.lock');
    if (await pubspecLock.exists()) {
      await pubspecLock.delete();
      print('Removido pubspec.lock');
    }
    final cleanResult = await Process.run('flutter', ['clean'], workingDirectory: dir.path);
    stdout.write(cleanResult.stdout);
    stderr.write(cleanResult.stderr);
    final pubGetResult = await Process.run('flutter', ['pub', 'get'], workingDirectory: dir.path);
    stdout.write(pubGetResult.stdout);
    stderr.write(pubGetResult.stderr);
    print('--- Limpeza concluída em: ${dir.path} ---');
  }
  print('\nLimpeza finalizada!');
}

Future<void> _runAnalyzeCommand() async {
  final analysisService = AnalysisService();
  final projectPath = Directory.current.path;

  print('Executando comando "analyze"...');

  try {
    final List<DomainHealthEntity> results = await analysisService.analyzeProject(projectPath);

    print('\n--- Resultados da Análise ---');
    if (results.isEmpty) {
      print('Nenhum domínio encontrado ou analisado.');
    } else {
      for (final domain in results) {
        print(domain);
      }
    }
    print('-----------------------------\n');

    // TODO: Aqui será o ponto para gerar o relatório JSON compartilhado
  } catch (e) {
    print('Falha na análise: $e');
    exit(1);
  }
}
