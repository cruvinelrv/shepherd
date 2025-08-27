import 'dart:io';
import 'package:shepherd/src/sync/domain/services/path_validator_service.dart';

/// Comando para validar e criar caminhos essenciais da Shepherd CLI.
/// Pode ser chamado no início do fluxo de qualquer comando.
Future<void> validatePathsCommand(List<String> requiredPaths,
    {String? baseDir}) async {
  final root = baseDir ?? Directory.current.path;
  final yamlFiles = [
    '.shepherd/domains.yaml',
    '.shepherd/config.yaml',
    '.shepherd/feature_toggles.yaml',
    '.shepherd/environments.yaml',
    '.shepherd/project.yaml',
    '.shepherd/sync_config.yaml',
    '.shepherd/user_active.yaml',
  ];
  final dbFile = '.shepherd/shepherd.db';

  final foundYaml = <String>[];
  final createdYaml = <String>[];
  final missingYaml = <String>[];

  // Primeiro, verifica e reporta os arquivos ausentes
  for (final path in yamlFiles) {
    final fullPath = path.startsWith('/')
        ? path
        : Directory(root).uri.resolve(path).toFilePath();
    final exists = File(fullPath).existsSync();
    if (exists) {
      foundYaml.add(fullPath);
    } else {
      missingYaml.add(fullPath);
    }
  }

  if (missingYaml.isNotEmpty) {
    print('Arquivos YAML ausentes (serão criados automaticamente):');
    for (var m in missingYaml) {
      print('  ✗ $m');
    }
  }

  // Cria os arquivos ausentes
  for (final fullPath in missingYaml) {
    File(fullPath).createSync(recursive: true);
    File(fullPath).writeAsStringSync('');
    createdYaml.add(fullPath);
  }

  final dbFullPath = Directory(root).uri.resolve(dbFile).toFilePath();
  final dbExists = File(dbFullPath).existsSync();
  var dbCreated = false;
  if (!dbExists) {
    File(dbFullPath).createSync(recursive: true);
    dbCreated = true;
  }

  print('Arquivos YAML em .shepherd:');
  if (foundYaml.isNotEmpty) {
    for (var f in foundYaml) {
      print('  ✔ $f');
    }
  } else {
    print('  Nenhum arquivo YAML localizado.');
  }
  if (createdYaml.isNotEmpty) {
    print('Arquivos YAML criados:');
    for (var c in createdYaml) {
      print('  ✚ $c');
    }
  }

  print('Banco de dados em .shepherd:');
  if (dbExists) {
    print('  ✔ $dbFullPath');
  } else if (dbCreated) {
    print('  ✚ $dbFullPath (criado automaticamente)');
  } else {
    print('  shepherd.db não localizado.');
  }

  if (foundYaml.isEmpty && createdYaml.isEmpty) {
    print('Nenhum arquivo YAML localizado ou criado.');
  }
  if (!dbExists && !dbCreated) {
    print('shepherd.db não localizado ou criado.');
  }

  // Usa o PathValidatorService para validar todos os caminhos
  final errors =
      PathValidatorService.validatePaths([...yamlFiles, dbFile], baseDir: root);

  if (errors.isNotEmpty) {
    print('[Shepherd][ERRO] Caminhos não encontrados:');
    errors.forEach(print);
    print('Corrija os caminhos acima antes de continuar.');
    exit(1);
  } else {
    print(
        '[Shepherd][DEBUG] Todos os arquivos essenciais foram localizados ou criados.');
  }
}
