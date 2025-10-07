import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/feature_toggle_entity.dart';
import 'package:shepherd/src/sync/domain/services/feature_toggle_exporter.dart';

Future<void> runEditFeatureToggleCommand() async {
  final db = FeatureToggleDatabase(Directory.current.path);
  stdout.write('Feature Toggle ID to edit: ');
  final idInput = stdin.readLineSync();
  final id = int.tryParse(idInput ?? '');
  if (id == null) {
    print('Invalid ID.');
    return;
  }
  stdout.write('New name (leave blank to keep): ');
  final newName = stdin.readLineSync();
  stdout.write('Enabled? (y/n, leave blank to keep): ');
  final enabledInput = stdin.readLineSync();
  stdout.write('Domain (leave blank to keep): ');
  final domain = stdin.readLineSync();
  stdout.write('Description (leave blank to keep): ');
  final description = stdin.readLineSync();

  // Busca o toggle atual
  final toggles = await db.getAllFeatureToggles();
  final current = toggles.firstWhere((t) => t.id == id,
      orElse: () => throw Exception('Feature toggle not found.'));

  final updated = FeatureToggleEntity(
    id: current.id,
    name: newName != null && newName.isNotEmpty ? newName : current.name,
    enabled: enabledInput == null || enabledInput.isEmpty
        ? current.enabled
        : (enabledInput.toLowerCase() == 'y' ||
            enabledInput.toLowerCase() == 's'),
    domain: domain != null && domain.isNotEmpty ? domain : current.domain,
    description: description != null && description.isNotEmpty
        ? description
        : current.description,
  );

  await db.updateFeatureToggleById(id, updated);
  await exportFeatureTogglesToYaml(db, Directory.current.path);
  print(
      'Feature toggle [${updated.id}] "${updated.name}" updated successfully!');
}
