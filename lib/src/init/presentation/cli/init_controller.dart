import 'dart:io';
import 'package:shepherd/src/init/presentation/cli/init/init_menu.dart';

class InitController {
  Future<void> handleInit({bool fromMenu = false}) async {
    await showInitMenu();
  }

  Future<void> handleDbAndYamlInit(File shepherdDbPath, List<FileSystemEntity> yamlFiles) async {
    if (!shepherdDbPath.existsSync()) {
      if (yamlFiles.isNotEmpty) {
        stdout.write(
            'shepherd.db not found, but YAML files were found. Do you want to run "shepherd pull" to create the database from YAMLs? (y/N): ');
        final resp = stdin.readLineSync()?.trim().toLowerCase();
        if (_isYes(resp)) {
          await Process.run('shepherd', ['pull']);
          print('shepherd pull executed.');
        } else {
          print(
              'shepherd.db will be created empty. The data from YAML files will be overwritten if you run shepherd init.');
          final shepherdDir = Directory(shepherdDbPath.parent.path);
          if (!shepherdDir.existsSync()) shepherdDir.createSync(recursive: true);
          shepherdDbPath.createSync();
          stdout.write('Do you want to run "shepherd init" to start a new project? (y/N): ');
          final respInit = stdin.readLineSync()?.trim().toLowerCase();
          if (_isYes(respInit)) {
            await handleInit();
            return;
          } else {
            print('Operation cancelled. Empty shepherd.db created, but not initialized.');
            exit(0);
          }
        }
      } else {
        stdout.write(
            'shepherd.db and YAML files not found. Do you want to run "shepherd init" to start a new project? (y/N): ');
        final resp = stdin.readLineSync()?.trim().toLowerCase();
        if (_isYes(resp)) {
          await handleInit();
          return;
        } else {
          print('Operation cancelled. shepherd.db was not created.');
          exit(0);
        }
      }
    } else {
      // Check if the database is empty (0 bytes) or has no tables
      bool isEmptyDb = shepherdDbPath.lengthSync() == 0;
      if (!isEmptyDb) {
        try {
          // This should be handled by sync controller
        } catch (_) {
          isEmptyDb = true;
        }
      }
      if (isEmptyDb) {
        print('The file shepherd.db exists but is empty or has no tables.');
        while (true) {
          print('\nChoose an option to initialize the database:');
          if (yamlFiles.isNotEmpty) {
            print('[1] shepherd pull (recreate from YAMLs)');
            print('[2] shepherd init (start a new project)');
            print('[3] Exit');
            stdout.write('Enter the number of the desired option: ');
            final opt = stdin.readLineSync()?.trim();
            if (opt == '1') {
              await Process.run('shepherd', ['pull']);
              print('shepherd pull executed.');
              break;
            } else if (opt == '2') {
              await handleInit();
              return;
            } else if (opt == '3') {
              print('Operation cancelled. shepherd.db remains empty.');
              exit(0);
            } else {
              print('Invalid option.');
            }
          } else {
            print('[1] shepherd init (start a new project)');
            print('[2] Exit');
            stdout.write('Enter the number of the desired option: ');
            final opt = stdin.readLineSync()?.trim();
            if (opt == '1') {
              await handleInit();
              return;
            } else if (opt == '2') {
              print('Operation cancelled. shepherd.db remains empty.');
              exit(0);
            } else {
              print('Invalid option.');
            }
          }
        }
      }
    }
  }

  bool _isYes(String? resp) {
    if (resp == null) return false;
    return resp == 'y' || resp == 'yes' || resp == 's' || resp == 'sim';
  }
}
