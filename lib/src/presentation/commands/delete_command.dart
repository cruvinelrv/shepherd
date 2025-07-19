import 'package:shepherd/src/domain/usecases/delete_usecase.dart';
import 'package:shepherd/src/presentation/controllers/delete_controller.dart';
import 'package:shepherd/src/utils/project_utils.dart';

Future<void> runDeleteCommand(String domainName) async {
  final shepherdDb = openShepherdDb();
  final useCase = DeleteUseCase(shepherdDb);
  final controller = DeleteController(useCase);
  await controller.run(domainName);
  await shepherdDb.close();
}
