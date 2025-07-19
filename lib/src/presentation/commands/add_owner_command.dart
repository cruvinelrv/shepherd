import 'package:shepherd/src/domain/usecases/add_owner_usecase.dart';
import 'package:shepherd/src/presentation/controllers/add_owner_controller.dart';
import 'package:shepherd/src/utils/project_utils.dart';

Future<void> runAddOwnerCommand(String domainName) async {
  final shepherdDb = openShepherdDb();
  final useCase = AddOwnerUseCase(shepherdDb);
  final controller = AddOwnerController(useCase);
  await controller.run(domainName);
  await shepherdDb.close();
}
