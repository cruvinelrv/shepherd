import 'package:shepherd/src/domain/usecases/config_usecase.dart';
import 'package:shepherd/src/presentation/controllers/config_controller.dart';
import 'package:shepherd/src/utils/config_utils.dart';
import 'package:shepherd/src/data/datasources/local/domains_database.dart';

Future<void> runConfigCommand() async {
  final configDb = openConfigDb();
  final domainsDb = DomainsDatabase(configDb.projectPath);
  final useCase = ConfigUseCase(configDb, domainsDb);
  final controller = ConfigController(useCase);
  await controller.run();
  await configDb.close();
  await domainsDb.close();
}
