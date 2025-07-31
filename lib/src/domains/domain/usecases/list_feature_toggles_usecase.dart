import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/feature_toggle_entity.dart';

class ListFeatureTogglesUseCase {
  final FeatureToggleDatabase db;
  ListFeatureTogglesUseCase(this.db);

  Future<List<FeatureToggleEntity>> getAll() async {
    return await db.getAllFeatureToggles();
  }
}
