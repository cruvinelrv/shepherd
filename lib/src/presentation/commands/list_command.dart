import 'package:shepherd/src/domain/usecases/list_usecase.dart';
import 'package:shepherd/src/presentation/controllers/list_controller.dart';
import 'package:shepherd/src/utils/project_utils.dart';

Future<void> runListCommand() async {
  final shepherdDb = openShepherdDb();
  final useCase = ListUseCase(shepherdDb);
  final controller = ListController(useCase);
  await controller.run();
  await shepherdDb.close();
}
