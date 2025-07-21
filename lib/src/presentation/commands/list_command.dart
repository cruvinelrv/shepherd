import 'package:shepherd/src/domain/usecases/list_usecase.dart';
import 'package:shepherd/src/presentation/controllers/list_controller.dart';
import 'package:shepherd/src/utils/list_utils.dart';

Future<void> runListCommand() async {
  final domainsDb = openDomainsDb();
  final useCase = ListUseCase(domainsDb);
  final controller = ListController(useCase);
  await controller.run();
  await domainsDb.close();
}
