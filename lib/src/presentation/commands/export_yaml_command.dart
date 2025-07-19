import 'package:shepherd/src/domain/usecases/export_yaml_usecase.dart';
import 'package:shepherd/src/presentation/controllers/export_yaml_controller.dart';
import 'package:shepherd/src/utils/project_utils.dart';

Future<void> runExportYamlCommand() async {
  final shepherdDb = openShepherdDb();
  final useCase = ExportYamlUseCase(shepherdDb);
  final controller = ExportYamlController(useCase);
  await controller.run();
  await shepherdDb.close();
}
