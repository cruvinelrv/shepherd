import 'dart:io';
import 'package:shepherd/src/init/presentation/cli/init/init_menu.dart';

class InitController {
  Future<void> handleInit({bool fromMenu = false}) async {
    await showInitMenu();
  }

  Future<void> handleDbAndYamlInit(
      File shepherdDbPath, List<FileSystemEntity> yamlFiles) async {
    if (!shepherdDbPath.existsSync()) {
      final shepherdDir = Directory(shepherdDbPath.parent.path);
      // Shepherd.db path: ${shepherdDbPath.path}
      // Database directory path: ${shepherdDir.path}
      if (!shepherdDir.existsSync()) {
        shepherdDir.createSync(recursive: true);
        // Database directory created.
      }
      // Creates shepherd.db only inside .shepherd
      shepherdDbPath.createSync();
      print(
          '[Shepherd] shepherd.db not found. Automatically created empty in .shepherd/.');
    }
  }
}
