import 'dart:io';
import 'init/init_menu.dart';
import 'domains_menu.dart';
import 'config_menu.dart';
import 'tools_menu.dart';
import 'deploy_menu.dart';
import 'package:shepherd/src/presentation/commands/commands.dart';

Future<void> showGeneralMenuLoop() async {
  while (true) {
    stdout.write('\nShepherd Main Menu\n');
    stdout
        .write('1. Domains\n2. Config\n3. Deploy\n4. Tools\n5. Init\n0. Exit\nSelect an option: ');
    final input = stdin.readLineSync();
    switch (input?.trim()) {
      case '1':
        await showDomainsMenuLoop(
          runAnalyzeCommand: runAnalyzeCommand,
          runAddOwnerCommand: runAddOwnerCommand,
          runListCommand: runListCommand,
          runExportYamlCommand: runExportYamlCommand,
          runDeleteCommand: runDeleteCommand,
        );
        break;
      case '2':
        await showConfigMenuLoop(
          runConfigCommand: runConfigCommand,
        );
        break;
      case '3':
        await showDeployMenuLoop(
          runChangelogCommand: runChangelogCommand,
          runAzureOpenPrCommand: runAzureOpenPrCommand,
        );
        break;
      case '4':
        await showToolsMenuLoop(
          runCleanCommand: runCleanCommand,
          runLinterCommand: runLinterCommand,
          runFormatCommand: runFormatCommand,
          runAzureCliInstallCommand: runAzureCliInstallCommand,
          runGithubCliInstallCommand: runGithubCliInstallCommand,
        );
        break;
      case '5':
        await showInitMenu();
        break;
      case '0':
        print('Exiting Shepherd CLI.');
        exit(0);
      default:
        print('Invalid option. Please try again.');
    }
  }
}
