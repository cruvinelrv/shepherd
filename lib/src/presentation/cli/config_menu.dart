import 'dart:io';
import 'input_utils.dart';
import 'dart:convert';
import 'package:shepherd/src/data/datasources/local/shepherd_database.dart';
import 'package:shepherd/src/presentation/controllers/edit_person_controller.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';

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
        final db = ShepherdDatabase(Directory.current.path);
        final controller = EditPersonController(db);
        await controller.run();
        pauseForEnter();
        break;
      case '3':
        // Selecionar tipo de repositório
        final repoType = readNonEmptyInput('Tipo de repositório (github/azure): ').toLowerCase();
        if (repoType != 'github' && repoType != 'azure') {
          print('Tipo inválido. Use "github" ou "azure".');
          pauseForEnter();
          break;
        }
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
        print('Tipo de repositório salvo como "$repoType" em .shepherd/config.json');
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
  3. Selecionar tipo de repositório (github/azure)
  9. Back to main menu
  0. Exit

Select an option (number):
''');
}
