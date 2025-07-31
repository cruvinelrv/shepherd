import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/feature_toggle_entity.dart';

class AddFeatureToggleUseCase {
  final FeatureToggleDatabase db;
  AddFeatureToggleUseCase(this.db);

  Future<void> addFeatureToggle(FeatureToggleEntity toggle) async {
    await db.insertFeatureToggle(toggle);
  }
}
