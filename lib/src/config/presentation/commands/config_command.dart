import '../../../domains/data/datasources/local/domains_database.dart';
import '../../../domains/domain/usecases/config_usecase.dart';
import '../../../utils/config_utils.dart';
import '../controllers/config_controller.dart';

Future<void> runConfigCommand() async {
  final configDb = openConfigDb();
  final domainsDb = DomainsDatabase(configDb.projectPath);
  final useCase = ConfigUseCase(configDb, domainsDb);
  final controller = ConfigController(useCase);
  await controller.run();
  await configDb.close();
  await domainsDb.close();
}
