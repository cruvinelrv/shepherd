import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';
import 'package:shepherd/src/sync/domain/services/feature_toggle_exporter.dart';

Future<void> runDeleteFeatureToggleCommand() async {
  final db = FeatureToggleDatabase(Directory.current.path);
  stdout.write('Feature Toggle ID to delete: ');
  final idInput = stdin.readLineSync();
  final id = int.tryParse(idInput ?? '');
  if (id == null) {
    print('Invalid ID.');
    return;
  }
  await db.deleteFeatureToggleById(id);
  await exportFeatureTogglesToYaml(db, Directory.current.path);
  print('Feature toggle [$id] deleted successfully!');
}
