import 'package:shepherd/src/domain/usecases/export_yaml_usecase.dart';
import 'package:shepherd/src/presentation/controllers/export_yaml_controller.dart';
import 'package:shepherd/src/utils/owner_utils.dart';

Future<void> runExportYamlCommand() async {
  final domainsDb = openDomainsDb();
  final useCase = ExportYamlUseCase(domainsDb);
  final controller = ExportYamlController(useCase);
  await controller.run();
  await domainsDb.close();
}
