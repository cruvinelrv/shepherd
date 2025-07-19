import 'package:shepherd/src/domain/usecases/config_usecase.dart';
import 'package:shepherd/src/presentation/controllers/config_controller.dart';
import 'package:shepherd/src/utils/project_utils.dart';

Future<void> runConfigCommand() async {
  final shepherdDb = openShepherdDb();
  final useCase = ConfigUseCase(shepherdDb);
  final controller = ConfigController(useCase);
  await controller.run();
  await shepherdDb.close();
}
