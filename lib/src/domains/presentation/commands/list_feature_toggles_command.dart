import 'dart:io';

import '../../../menu/presentation/cli/input_utils.dart';
import '../../data/datasources/local/feature_toggle_database.dart';
import '../../domain/usecases/list_feature_toggles_usecase.dart';

Future<void> runListFeatureTogglesCommand() async {
  final db = FeatureToggleDatabase(Directory.current.path);
  final useCase = ListFeatureTogglesUseCase(db);
  final toggles = await useCase.getAll();
  if (toggles.isEmpty) {
    print('No feature toggles found.');
    return;
  }
  print('Feature Toggles:');
  for (final t in toggles) {
    print(
        '- [${t.id}] ${t.name} [${t.enabled ? 'enabled' : 'disabled'}] | Domain: ${t.domain}');
    print('  Description: ${t.description}\n');
  }
  pauseForEnter();
}
