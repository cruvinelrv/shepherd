import 'dart:io';
import 'input_utils.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import 'package:shepherd/src/config/data/datasources/local/config_database.dart';
import 'package:shepherd/src/config/presentation/controllers/edit_person_controller.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';

import 'environments_menu.dart';

Future<void> showConfigMenuLoop({
  required Future<void> Function() runConfigCommand,
}) async {
  while (true) {
    print(
        '\n${AnsiColors.yellow}================ CONFIG MENU ==================${AnsiColors.reset}');
    printConfigMenu();
    final input = stdin.readLineSync();
    print('');
    switch (input?.trim()) {
      case '1':
        await runConfigCommand();
        pauseForEnter();
        break;
      case '2':
        final db = ConfigDatabase(Directory.current.path);
        final controller = EditPersonController(db);
        await controller.run();
        await db.close();
        pauseForEnter();
        break;
      case '3':
        // Select repository type
        final repoType = readNonEmptyInput('Repository type (github/azure): ').toLowerCase();
        if (repoType != 'github' && repoType != 'azure') {
          print('Invalid type. Use "github" or "azure".');
          pauseForEnter();
          break;
        }
        final shepherdDir = Directory('.shepherd');
        if (!shepherdDir.existsSync()) {
          shepherdDir.createSync(recursive: true);
        }
        final configFile = File('.shepherd/config.yaml');
        Map config = {};
        if (configFile.existsSync()) {
          try {
            final content = configFile.readAsStringSync();
            final map = loadYaml(content);
            if (map is Map) config = Map.from(map);
          } catch (_) {}
        }
        config['repoType'] = repoType;
        final writer = YamlWriter();
        configFile.writeAsStringSync(writer.write(config), mode: FileMode.write);
        print('Repository type saved as "$repoType" in .shepherd/config.yaml');
        pauseForEnter();
        break;
      case '4':
        // Environments management
        await showEnvironmentsMenu();
        pauseForEnter();
        break;
      case '0':
        print('Exiting Shepherd CLI.');
        exit(0);
      case '9':
        print('Returning to main menu...');
        return;
      default:
        print('Invalid option. Please try again.');
        pauseForEnter();
    }
    print('\n----------------------------------------------\n');
  }
}

void printConfigMenu() {
  print('''
Shepherd Config - Configuration and Settings

  1. Interactive configuration for Shepherd
  2. Edit person/owner GitHub username
  3. Select repository type (github/azure)
  4. Manage environments
  9. Back to main menu
  0. Exit

Select an option (number):
''');
}
