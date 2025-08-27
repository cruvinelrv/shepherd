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
      // Cria shepherd.db apenas dentro de .shepherd
      shepherdDbPath.createSync();
      print('[Shepherd] shepherd.db não encontrado. Criado vazio automaticamente em .shepherd/.');
    }
  }
}
