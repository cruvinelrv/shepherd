import 'package:shepherd/src/sync/domain/usecases/export_yaml_usecase.dart';

class ExportYamlController {
  final ExportYamlUseCase useCase;
  ExportYamlController(this.useCase);

  Future<void> run() async {
    await useCase.exportYaml();
  }
}
