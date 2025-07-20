import 'dart:io';
import 'dart:convert';
import 'package:shepherd/src/data/shepherd_database.dart';
import 'package:shepherd/src/presentation/controllers/add_owner_controller.dart';
import 'package:shepherd/src/domain/usecases/add_owner_usecase.dart';
import 'input_utils.dart';

Future<void> showInitMenu() async {
  print('\n================ SHEPHERD INIT ================\n');
  final db = ShepherdDatabase(Directory.current.path);

  // 1. Cadastro de domínios
  print('--- Domain registration ---');
  String? domainName;
  while (domainName == null || domainName.isEmpty) {
    domainName = readLinePrompt('Enter the main domain name for this project: ');
    if (domainName == null || domainName.trim().isEmpty) {
      print('Domain name cannot be empty.');
      domainName = null;
    }
  }

  print('\n--- Owner registration ---');
  while (true) {
    final addOwnerController = AddOwnerController(
      AddOwnerUseCase(db),
    );
    await addOwnerController.run(domainName);
    final addMore = readLinePrompt('Add another owner? (y/n): ');
    if (addMore == null || addMore.toLowerCase() != 'y') break;
  }

  // 3. Registrar domínio na tabela domain_health se não existir
  final existingDomains = await db.getAllDomainHealths();
  final alreadyExists = existingDomains.any((d) => d.domainName == domainName);
  if (!alreadyExists) {
    // Buscar owners cadastrados para o domínio
    final owners = await db.getOwnersForDomain(domainName);
    final ownerIds = owners.map((o) => o['id'] as int).toList();
    await db.insertDomain(
      domainName: domainName,
      score: 0.0,
      commits: 0,
      days: 0,
      warnings: '',
      personIds: ownerIds,
      projectPath: Directory.current.path,
    );
    print('Domain "$domainName" registered in database.');
  }

  // 4. Escolha do tipo de repositório
  print('\n--- Repository type ---');
  String? repoType;
  while (repoType != 'github' && repoType != 'azure') {
    repoType = readLinePrompt('Repository type (github/azure): ');
    repoType ??= '';
    repoType = repoType.toLowerCase();
    if (repoType != 'github' && repoType != 'azure') {
      print('Please enter "github" or "azure".');
    }
  }
  // Salva no config.json
  final shepherdDir = Directory('.shepherd');
  if (!shepherdDir.existsSync()) {
    shepherdDir.createSync(recursive: true);
  }
  final configFile = File('.shepherd/config.json');
  Map<String, dynamic> config = {};
  if (configFile.existsSync()) {
    try {
      config = jsonDecode(configFile.readAsStringSync());
    } catch (_) {}
  }
  config['repoType'] = repoType;
  configFile.writeAsStringSync(jsonEncode(config), mode: FileMode.write);
  print('Repository type "$repoType" saved in .shepherd/config.json');

  // 4. Se GitHub, garantir github_username dos owners
  if (repoType == 'github') {
    print('\n--- GitHub usernames for owners ---');
    final persons = await db.getAllPersons();
    for (final p in persons) {
      final gh = (p['github_username'] ?? '').toString().trim();
      if (gh.isEmpty) {
        print('Owner: ${p['first_name']} ${p['last_name']} <${p['email']}>');
        final newGh = readLinePrompt('GitHub username: ');
        if (newGh != null && newGh.trim().isNotEmpty) {
          await db.updatePersonGithubUsername(p['id'] as int, newGh.trim());
        }
      }
    }
    print('All owners now have GitHub usernames.');
  }

  // 5. Resumo final
  print('\n--- Shepherd project initialized! ---');
  print('Domain: $domainName');
  print('Repository type: $repoType');
  final owners = await db.getOwnersForDomain(domainName);
  print('Owners:');
  for (final o in owners) {
    print(
        '  - ${o['first_name']} ${o['last_name']} <${o['email']}> (${o['type']})${o['github_username'] != null && (o['github_username'] as String).isNotEmpty ? ' [GitHub: ${o['github_username']}]' : ''}');
  }
  print('\nYou can edit domains, owners, or config later using the regular menus.');
}
