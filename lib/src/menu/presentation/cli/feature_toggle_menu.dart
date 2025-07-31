import 'dart:io';
import 'package:shepherd/src/domains/presentation/commands/add_feature_toggle_command.dart';
import 'package:shepherd/src/domains/presentation/commands/list_feature_toggles_command.dart';
import 'package:shepherd/src/domains/presentation/commands/edit_feature_toggle_command.dart';
import 'package:shepherd/src/domains/presentation/commands/delete_feature_toggle_command.dart';

Future<void> showFeatureToggleMenu() async {
  while (true) {
    print(
        '''\nFeature Toggle Management\n\n  1. Add Feature Toggle\n  2. List Feature Toggles\n  3. Edit Feature Toggle\n  4. Delete Feature Toggle\n  9. Back to Domains Menu\n  0. Exit\n\nSelect an option (number):''');
    final input = stdin.readLineSync();
    print('');
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
      case '9':
        print('Returning to Domains Menu...');
        return;
      case '0':
        print('Exiting Shepherd CLI.');
        exit(0);
      default:
        print('Invalid option. Please try again.');
    }
    print('\n----------------------------------------------\n');
  }
}
