import 'dart:io';

import 'package:shepherd/src/menu/presentation/cli/input_utils.dart';
import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/usecases/list_feature_toggles_usecase.dart';

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
