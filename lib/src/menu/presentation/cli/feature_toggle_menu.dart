import 'dart:io';
import 'package:shepherd/src/domains/presentation/commands/feature_toggles/feature_toggles_commands.dart';

Future<void> showFeatureToggleMenu() async {
  while (true) {
    print('''
🔧 Feature Toggle Management

  Basic Operations:
  1. Add Feature Toggle
  2. List Feature Toggles  
  3. Edit Feature Toggle
  4. Delete Feature Toggle

  DynamoDB Import/Export (Terraform ↔ Shepherd):
  5. Configure Import Fields (creates YAML config)
  6. Import Terraform File (.tf → database)
  7. Export to Terraform (.tf file)

  8. Back to Domains Menu
  0. Exit

Select an option:''');

    final input = stdin.readLineSync();
    print('');

    try {
      switch (input?.trim()) {
        case '1':
          await runAddFeatureToggleCommand();
          break;
        case '2':
          await runListFeatureTogglesCommand();
          break;
        case '3':
          await runEditFeatureToggleCommand();
          break;
        case '4':
          await runDeleteFeatureToggleCommand();
          break;
        case '5':
          await runConfigureImportFieldsCommand();
          break;
        case '6':
          await runDynamicImportCommand();
          break;
        case '7':
          await runExportToTerraformCommand();
          break;
        case '8':
          print('Returning to Domains Menu...');
          return;
        case '0':
          print('Exiting Shepherd CLI.');
          exit(0);
        default:
          print('Invalid option. Please try again.');
      }
    } catch (e) {
      print('❌ Error: $e');
    }

    print('\n----------------------------------------------\n');
  }
}
