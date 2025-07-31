import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/feature_toggle_entity.dart';

class EditFeatureToggleUseCase {
  final FeatureToggleDatabase db;
  EditFeatureToggleUseCase(this.db);

  Future<void> updateFeatureToggleById(
      int id, FeatureToggleEntity updated) async {
    await db.updateFeatureToggleById(id, updated);
  }
}
