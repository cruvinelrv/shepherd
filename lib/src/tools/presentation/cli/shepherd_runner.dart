import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'dart:io';
import 'package:shepherd/src/init/presentation/cli/init_controller.dart';
import 'package:shepherd/src/sync/presentation/cli/sync_controller.dart';
import 'package:shepherd/src/menu/presentation/cli/general_menu.dart'
    show showGeneralMenuLoop;
import 'package:shepherd/src/menu/presentation/cli/menu.dart'
    show printShepherdHelp;
import 'package:shepherd/src/menu/presentation/cli/domains_menu.dart'
    show showDomainsMenuLoop;
import 'package:shepherd/src/menu/presentation/cli/config_menu.dart'
    show showConfigMenuLoop;
import 'package:shepherd/src/menu/presentation/cli/tools_menu.dart'
    show showToolsMenuLoop;
import 'package:shepherd/src/menu/presentation/cli/deploy_menu.dart'
    show runDeployStepByStep;
import 'package:shepherd/src/tools/presentation/cli/command_registry.dart';
import 'package:shepherd/src/tools/presentation/commands/dashboard_command.dart';
import 'package:shepherd/src/domains/presentation/commands/analyze_command.dart'
    show runAnalyzeCommand;
import 'package:shepherd/src/domains/presentation/commands/add_owner_command.dart'
    show runAddOwnerCommand;
import 'package:shepherd/src/domains/presentation/commands/list_command.dart'
    show runListCommand;
import 'package:shepherd/src/sync/presentation/commands/export_yaml_command.dart'
    show runExportYamlCommand;
import 'package:shepherd/src/domains/presentation/commands/delete_domain_command.dart'
    show runDeleteCommand;
import 'package:shepherd/src/config/presentation/commands/config_command.dart'
    show runConfigCommand;
import 'package:shepherd/src/deploy/presentation/controllers/changelog_command.dart'
    show runChangelogCommand;
import 'package:shepherd/src/deploy/presentation/controllers/azure_pr_command.dart'
    show runAzureOpenPrCommand;
import 'package:shepherd/src/tools/presentation/commands/clean_command.dart'
    show runCleanCommand;
import 'package:shepherd/src/tools/presentation/cli/commands/linter_command.dart'
    show runLinterCommand;
import 'package:shepherd/src/config/presentation/commands/version_command.dart'
    show runVersionCommand;
import 'package:shepherd/src/config/presentation/commands/about_command.dart'
    show runAboutCommand;

Future<void> runShepherd(List<String> arguments) async {
  final shepherdDbPath = File('.shepherd/shepherd.db');
  final syncConfigFile = File('.shepherd/sync_config.yaml');
  final yamlFiles = syncConfigFile.existsSync()
      ? <FileSystemEntity>[syncConfigFile]
      : <FileSystemEntity>[];
  final initController = InitController();
  final userActiveFile = File('.shepherd/user_active.yaml');
  final hasUser =
      userActiveFile.existsSync() && userActiveFile.lengthSync() > 0;
  await initController.handleDbAndYamlInit(shepherdDbPath, yamlFiles);
  final syncController = SyncController();
  await syncController.checkAndSyncYamlDbConsistency(Directory.current.path);

  final projectYamlFile = File('.shepherd/project.yaml');
  bool projectYamlValid = false;
  if (projectYamlFile.existsSync() && projectYamlFile.lengthSync() > 0) {
    try {
      final content = projectYamlFile.readAsStringSync();
      final loaded = content.trim().isEmpty ? null : loadYaml(content);
      if (loaded is Map && loaded['id'] != null && loaded['name'] != null) {
        projectYamlValid = true;
      }
    } catch (_) {}
  }
  // Se project.yaml existe mas está vazio, considera inválido e propõe init/pull
  if (projectYamlFile.existsSync() && projectYamlFile.lengthSync() == 0) {
    projectYamlValid = false;
    // Se project.yaml está vazio, só propor init
    if (!hasUser &&
        (arguments.isEmpty ||
            (arguments.length == 1 && arguments.first == 'init'))) {
      stdout.write(
          'Arquivo project.yaml está vazio. Deseja inicializar um novo projeto? [s/N]: ');
      final resp = stdin.readLineSync()?.trim().toLowerCase();
      if (resp == 's' || resp == 'sim' || resp == 'y' || resp == 'yes') {
        await initController.handleInit();
        // Após rodar init, verifica se project.yaml foi preenchido
        if (projectYamlFile.existsSync() && projectYamlFile.lengthSync() > 0) {
          print('Projeto inicializado com sucesso.');
        } else {
          stderr.writeln(
              '\x1B[31mO arquivo project.yaml continua vazio após inicialização. Encerrando para evitar loop.\x1B[0m');
          exit(1);
        }
      } else {
        print('Operação cancelada.');
      }
      return;
    }
  }
  final shepherdDbFile = File('.shepherd/shepherd.db');

  // Se project.yaml está válido, considera projeto inicializado
  if (projectYamlValid) {
    // Se shepherd.db existe, valida consistência
    if (shepherdDbFile.existsSync()) {
      final syncController = SyncController();
      await syncController
          .checkAndSyncYamlDbConsistency(Directory.current.path);
    }
    // Segue normalmente para menus ou comandos
  } else if (!hasUser &&
      (arguments.isEmpty ||
          (arguments.length == 1 && arguments.first == 'init'))) {
    // Se não há usuário e project.yaml não está válido, pergunta init/pull
    await _promptInitOrPull(false);
    // Após init, valida se YAMLs foram criados
    final yamlFilesCreated = [
      '.shepherd/project.yaml',
      '.shepherd/domains.yaml',
      '.shepherd/environments.yaml',
      '.shepherd/config.yaml',
      '.shepherd/feature_toggles.yaml',
    ].every((path) => File(path).existsSync() && File(path).lengthSync() > 0);
    if (!yamlFilesCreated) {
      stderr.writeln(
          '\x1B[31mOs arquivos YAML não foram criados corretamente. Encerrando o processo.\x1B[0m');
      exit(1);
    }
    // Se criados, segue normalmente
  }

  if (arguments.isEmpty) {
    await showGeneralMenuLoop();
    return;
  }
  await _runShepherdCommands(arguments, initController);
  // Se o comando for 'init', chama o menu interativo completo
  if (arguments.length == 1 && arguments.first == 'init') {
    await initController.handleInit();
    return;
  }
}

// Função auxiliar para identificar comandos de menu
bool _isMenuCommand(String name) {
  const menuCommands = {'domains', 'config', 'deploy', 'tools'};
  return menuCommands.contains(name);
}

Future<void> _promptInitOrPull(bool hasYaml) async {
  if (hasYaml) {
    stdout.write(
        'Nenhum usuário registrado. Deseja inicializar um novo projeto (init) ou importar arquivos YAML existentes (pull)? [init/pull/N]: ');
    final resp = stdin.readLineSync()?.trim().toLowerCase();
    if (resp == 'init') {
      final initController = InitController();
      await initController.handleInit();
    } else if (resp == 'pull') {
      await runShepherd(['pull']);
    } else {
      print('Operação cancelada.');
    }
  } else {
    stdout.write(
        'Nenhum arquivo YAML encontrado. Deseja inicializar um novo projeto? [s/N]: ');
    final resp = stdin.readLineSync()?.trim().toLowerCase();
    if (resp == 's' || resp == 'sim' || resp == 'y' || resp == 'yes') {
      await runShepherd(['init']);
    } else {
      print('Operação cancelada.');
    }
  }
}

Future<void> _runShepherdCommands(
    List<String> arguments, InitController initController) async {
  // Comandos diretos do registry SEMPRE funcionam, exceto init/pull
  final registry = buildCommandRegistry();
  final directCommand = arguments.isNotEmpty ? arguments.first : null;
  final directHandler = directCommand != null ? registry[directCommand] : null;
  // Menus interativos SEMPRE funcionam sem argumentos
  if (directCommand != null && arguments.length == 1) {
    switch (directCommand) {
      case 'domains':
        await showDomainsMenuLoop(
          runAnalyzeCommand: runAnalyzeCommand,
          runAddOwnerCommand: runAddOwnerCommand,
          runListCommand: runListCommand,
          runExportYamlCommand: runExportYamlCommand,
          runDeleteCommand: runDeleteCommand,
        );
        return;
      case 'config':
        await showConfigMenuLoop(
          runConfigCommand: runConfigCommand,
        );
        return;
      case 'deploy':
        await runDeployStepByStep(
          runChangelogCommand: runChangelogCommand,
          runAzureOpenPrCommand: runAzureOpenPrCommand,
        );
        return;
      case 'tools':
        await showToolsMenuLoop(
          runCleanCommand: runCleanCommand,
          runLinterCommand: runLinterCommand,
          runFormatCommand: (args) async =>
              print('Format command not implemented.'),
          runAzureCliInstallCommand: (args) async =>
              print('Azure CLI install not implemented.'),
          runGithubCliInstallCommand: (args) async =>
              print('GitHub CLI install not implemented.'),
        );
        return;
    }
  }
  if (directHandler != null &&
      directCommand != 'init' &&
      directCommand != 'pull') {
    await directHandler(arguments.sublist(1));
    return;
  }

  final parser = ArgParser();
  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    print(e.message);
    print('Usage: shepherd <command> [options]');
    print(parser.usage);
    exit(1);
  }
  final command = argResults.command;
  if (command == null) {
    print('No command specified.');
    print('Usage: shepherd <group>');
    printShepherdHelp();
    exit(1);
  }

  // Verifica arquivos essenciais apenas para comandos que realmente precisam deles (menus, init, pull)
  final essentialFiles = [
    'domains.yaml',
    'config.yaml',
    'feature_toggles.yaml',
    'environments.yaml',
    'project.yaml',
    'sync_config.yaml',
    'user_active.yaml',
    '.shepherd/shepherd.db',
  ];
  final missingOrEmptyFiles = essentialFiles.where((f) {
    final file = File('.shepherd/$f');
    if (!file.existsSync()) return true;
    if (f.endsWith('.yaml') && file.lengthSync() == 0) return true;
    return false;
  }).toList();
  if (missingOrEmptyFiles.isNotEmpty &&
      (command.name == 'init' ||
          command.name == 'pull' ||
          _isMenuCommand(command.name ?? ''))) {
    stderr.writeln('\x1B[31mProjeto Shepherd não está configurado!\x1B[0m');
    stderr.writeln(
        'Execute \x1B[36mshepherd pull\x1B[0m para importar os arquivos do projeto ou \x1B[36mshepherd init\x1B[0m para iniciar um novo.');
    exit(1);
  }

  // ...continua execução dos menus e comandos especiais...

  // Menus e switches especiais
  if (command.name == 'init' && command.arguments.isEmpty) {
    await initController.handleInit();
    return;
  }
  if (command.name == 'domains' && command.arguments.isEmpty) {
    await showDomainsMenuLoop(
      runAnalyzeCommand: runAnalyzeCommand,
      runAddOwnerCommand: runAddOwnerCommand,
      runListCommand: runListCommand,
      runExportYamlCommand: runExportYamlCommand,
      runDeleteCommand: runDeleteCommand,
    );
    return;
  }
  if (command.name == 'config' && command.arguments.isEmpty) {
    await showConfigMenuLoop(
      runConfigCommand: runConfigCommand,
    );
    return;
  }
  if (command.name == 'deploy' && command.arguments.isEmpty) {
    await runDeployStepByStep(
      runChangelogCommand: runChangelogCommand,
      runAzureOpenPrCommand: runAzureOpenPrCommand,
    );
    return;
  }
  if (command.name == 'clean') {
    await runCleanCommand(arguments);
    return;
  }

  if (command.name == 'tools' && command.arguments.isEmpty) {
    await showToolsMenuLoop(
      runCleanCommand: runCleanCommand,
      runLinterCommand: runLinterCommand,
      runFormatCommand: (args) async =>
          print('Format command not implemented.'),
      runAzureCliInstallCommand: (args) async =>
          print('Azure CLI install not implemented.'),
      runGithubCliInstallCommand: (args) async =>
          print('GitHub CLI install not implemented.'),
    );
    return;
  }
  switch (command.name) {
    case 'dashboard':
      await runDashboardCommand();
      return;
    case 'version':
      await runVersionCommand(command.arguments);
      return;
    case 'about':
      await runAboutCommand(command.arguments);
      return;
  }
  stderr.writeln('Unknown command: \x1B[31m${command.name}\x1B[0m');
  printShepherdHelp();
  exit(1);
}
