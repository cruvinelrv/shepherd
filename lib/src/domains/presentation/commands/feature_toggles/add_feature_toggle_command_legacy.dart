import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';
import 'package:shepherd/src/domains/presentation/controllers/add_feature_toggle_controller.dart';
import 'package:shepherd/src/domains/domain/usecases/add_feature_toggle_usecase.dart';
import 'package:shepherd/src/sync/domain/services/feature_toggle_exporter.dart';

Future<void> runAddFeatureToggleCommand() async {
  stdout.write('Feature Toggle name: ');
  final name = stdin.readLineSync() ?? '';
  stdout.write('Enabled? (y/n): ');
  final enabledInput = stdin.readLineSync()?.toLowerCase() ?? 'n';
  final enabled = enabledInput == 'y' || enabledInput == 's';
  stdout.write('Domain: ');
  final domain = stdin.readLineSync() ?? '';
  stdout.write('Description: ');
  final description = stdin.readLineSync() ?? '';

  final db = FeatureToggleDatabase(Directory.current.path);
  final controller = AddFeatureToggleController(AddFeatureToggleUseCase(db));
  await controller.run(
    name: name,
    enabled: enabled,
    domain: domain,
    description: description,
  );
  await exportFeatureTogglesToYaml(db, Directory.current.path);
  print('Feature toggle "$name" added successfully!');
}
