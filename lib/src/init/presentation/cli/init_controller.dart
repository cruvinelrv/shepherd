import 'dart:io';
import 'package:shepherd/src/init/presentation/cli/init/init_menu.dart';

class InitController {
  Future<void> handleInit({bool fromMenu = false}) async {
    await showInitMenu();
  }

  Future<void> handleDbAndYamlInit(File shepherdDbPath, List<FileSystemEntity> yamlFiles) async {
    if (!shepherdDbPath.existsSync()) {
      final shepherdDir = Directory(shepherdDbPath.parent.path);
      print('[Shepherd][DEBUG] Caminho do shepherd.db: ${shepherdDbPath.path}');
      print('[Shepherd][DEBUG] Caminho do diretório do banco: ${shepherdDir.path}');
      if (!shepherdDir.existsSync()) {
        shepherdDir.createSync(recursive: true);
        print('[Shepherd][DEBUG] Diretório do banco criado.');
      }
      if (yamlFiles.isNotEmpty) {
        print('[Shepherd] shepherd.db não encontrado. Recriando a partir dos YAMLs...');
        print('[Shepherd][DEBUG] Executando shepherd pull em: ${Directory.current.path}');
        try {
          final result = await Process.run('shepherd', ['pull'],
                  workingDirectory: Directory.current.path, runInShell: true)
              .timeout(const Duration(seconds: 20));
          print('[Shepherd][DEBUG] Saída do shepherd pull: ${result.stdout}');
          print('[Shepherd][DEBUG] Erros do shepherd pull: ${result.stderr}');
          print('[Shepherd][DEBUG] Exit code: ${result.exitCode}');
          if (result.exitCode != 0) {
            print('[Shepherd][ERRO] shepherd pull falhou. Verifique os YAMLs e permissões.');
          } else {
            print('[Shepherd] shepherd.db recriado a partir dos YAMLs.');
          }
        } catch (e) {
          print('[Shepherd][ERRO] shepherd pull travou ou excedeu o tempo limite. Erro: $e');
        }
      } else {
        shepherdDbPath.createSync();
        print('[Shepherd] shepherd.db não encontrado. Criado vazio automaticamente.');
      }
    }
  }
}
