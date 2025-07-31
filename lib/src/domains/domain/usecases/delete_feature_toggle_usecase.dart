import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';

class DeleteFeatureToggleUseCase {
  final FeatureToggleDatabase db;
  DeleteFeatureToggleUseCase(this.db);

  Future<void> deleteFeatureToggleById(int id) async {
    await db.deleteFeatureToggleById(id);
  }
}
