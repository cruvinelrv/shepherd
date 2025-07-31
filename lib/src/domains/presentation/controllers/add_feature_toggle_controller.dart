import 'package:shepherd/src/domains/domain/usecases/add_feature_toggle_usecase.dart';
import 'package:shepherd/src/domains/domain/entities/feature_toggle_entity.dart';

class AddFeatureToggleController {
  final AddFeatureToggleUseCase useCase;
  AddFeatureToggleController(this.useCase);

  Future<void> run({
    required String name,
    required bool enabled,
    required String domain,
    required String description,
  }) async {
    final toggle = FeatureToggleEntity(
      name: name,
      enabled: enabled,
      domain: domain,
      description: description,
    );
    await useCase.addFeatureToggle(toggle);
  }
}
