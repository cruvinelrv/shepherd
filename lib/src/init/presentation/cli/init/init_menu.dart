import '../../../../data/datasources/local/config_database.dart';
import '../../../../data/datasources/local/domains_database.dart';
import 'init_domain_prompt.dart';
import 'init_owner_prompt.dart';
import 'init_repo_type_prompt.dart';
import 'init_github_prompt.dart';
import 'init_summary.dart';
import 'init_cancel_exception.dart';
import 'init_project_prompt.dart';
import 'package:shepherd/src/domain/usecases/export_yaml_usecase.dart';
import 'package:yaml/yaml.dart';
import 'dart:io';
import 'dart:convert';

Future<void> showInitMenu() async {
  // Root directory check
  final shepherdDir = Directory('${Directory.current.path}/.shepherd');
  final devopsDir = Directory('${Directory.current.path}/devops');
  if (!shepherdDir.existsSync() || !devopsDir.existsSync()) {
    print(
        '\x1B[31mShepherd deve ser executado a partir da raiz do projeto (onde existem as pastas .shepherd e devops).\x1B[0m');
    print('Diretório atual: \'${Directory.current.path}\'');
    return;
  }

  // Warning if configuration already exists
  final projectFile = File('${shepherdDir.path}/project.yaml');
  final domainsFile = File('${devopsDir.path}/domains.yaml');
  if (projectFile.existsSync() && domainsFile.existsSync()) {
    print('\x1B[33mWarning: a Shepherd project is already initialized in this directory.\x1B[0m');
    print('Continuing may overwrite configuration and the devops/domains.yaml file.');
    stdout.write('Do you want to continue anyway? (y/N): ');
    final resp = stdin.readLineSync()?.trim().toLowerCase();
    if (resp != 's' && resp != 'sim' && resp != 'y' && resp != 'yes') {
      print('Operation cancelled.');
      return;
    }
  }
  print('\n================ SHEPHERD INIT ================\n');
  print('You can type 9 at any prompt to return to the main menu.');
  final db = DomainsDatabase(Directory.current.path);
  final configDb = ConfigDatabase(Directory.current.path);

  try {
    // 0. Project registration
    final shepherdDir = Directory('${Directory.current.path}/.shepherd');
    if (!await shepherdDir.exists()) {
      await shepherdDir.create(recursive: true);
    }
    final projectFile = File('${shepherdDir.path}/project.yaml');
    Map<String, String>? projectInfo;
    if (await projectFile.exists()) {
      // If project.yaml exists, load and show info, else prompt
      final content = await projectFile.readAsString();
      final loaded = loadYaml(content);
      if (loaded is Map && loaded['id'] != null && loaded['name'] != null) {
        print('Project already registered: ${loaded['name']} (id: ${loaded['id']})');
        projectInfo = {'id': loaded['id'].toString(), 'name': loaded['name'].toString()};
      } else {
        projectInfo = await promptProjectInfo(allowCancel: true);
      }
    } else {
      projectInfo = await promptProjectInfo(allowCancel: true);
      if (projectInfo != null) {
        final yamlContent = 'id: ${projectInfo['id']}\nname: ${projectInfo['name']}\n';
        await projectFile.writeAsString(yamlContent);
        print('Project registered: ${projectInfo['name']} (id: ${projectInfo['id']})');
      }
    }
    if (projectInfo == null) throw ShepherdInitCancelled();

    // 1. Environment registration
    final envFile = File('${shepherdDir.path}/environments.json');
    Map<String, String> environments = {};
    if (envFile.existsSync()) {
      try {
        final content = envFile.readAsStringSync();
        final map = jsonDecode(content);
        if (map is Map<String, dynamic>) {
          environments = map.map((k, v) => MapEntry(k, v.toString()));
        }
      } catch (_) {
        environments = {};
      }
    }
    print('\nCurrent environments:');
    if (environments.isEmpty) {
      print('  (none)');
    } else {
      environments.forEach((env, branch) {
        print('  $env: $branch');
      });
    }
    while (true) {
      stdout.write('Add a new environment (leave blank to finish): ');
      final env = stdin.readLineSync()?.trim();
      if (env == null || env.isEmpty) break;
      if (!environments.containsKey(env)) {
        stdout.write('Enter the branch for "$env": ');
        final branch = stdin.readLineSync()?.trim();
        if (branch != null && branch.isNotEmpty) {
          environments[env] = branch;
          print('Environment "$env" with branch "$branch" added.');
        } else {
          print('Invalid branch.');
        }
      } else {
        print('Environment already exists.');
      }
    }
    await envFile.writeAsString(jsonEncode(environments));
    print('Environments saved:');
    if (environments.isEmpty) {
      print('  (none)');
    } else {
      environments.forEach((env, branch) {
        print('  $env: $branch');
      });
    }

    // 2. Domain registration
    final domainName = await promptDomainName(allowCancel: true);
    if (domainName == null) throw ShepherdInitCancelled();

    // 3. Create domain immediately (with no owners yet)
    final existingDomains = await db.getAllDomainHealths();
    final alreadyExists = existingDomains.any((d) => d.domainName == domainName);
    if (!alreadyExists) {
      await db.insertDomain(
        domainName: domainName,
        score: 0.0,
        commits: 0,
        days: 0,
        warnings: '',
        personIds: [],
        projectPath: Directory.current.path,
      );
      print('Domain "$domainName" registered in database.');
    }

    // 4. Owner registration
    print('--- Owner registration ---');
    await promptOwners(db, domainName, allowCancel: true);

    // 5. Repository type selection and save
    final repoType = await promptRepoTypeAndSave(allowCancel: true);
    if (repoType == null) throw ShepherdInitCancelled();

    // 6. If GitHub, ensure owners have github_username
    if (repoType == 'github') {
      await ensureGithubUsernames(db, configDb, allowCancel: true);
    }

    // 7. Final summary
    await printInitSummary(db, domainName, repoType);

    // 8. Export domains.yaml automatically
    try {
      final exportYaml = await exportDomainsYaml(db);
      if (exportYaml) {
        print('domains.yaml file exported to devops/.');
      } else {
        print('Could not export domains.yaml.');
      }
    } catch (e) {
      print('Error exporting domains.yaml:'
          '\n  31m$e 0m');
    }
  } on ShepherdInitCancelled {
    print('Init cancelled. Returning to main menu.');
    return;
  }
}

// Função auxiliar para exportar domains.yaml
Future<bool> exportDomainsYaml(DomainsDatabase db) async {
  try {
    final useCase = ExportYamlUseCase(db);
    await useCase.exportYaml();
    return true;
  } catch (_) {
    return false;
  }
}
