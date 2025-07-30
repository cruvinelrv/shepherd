import 'package:shepherd/src/domains/domain/usecases/add_owner_usecase.dart';
import 'package:shepherd/src/domains/presentation/controllers/add_owner_controller.dart';
import 'package:shepherd/src/utils/owner_utils.dart';

Future<void> runAddOwnerCommand(String domainName) async {
  final domainsDb = openDomainsDb();
  final useCase = AddOwnerUseCase(domainsDb);
  final controller = AddOwnerController(useCase);
  await controller.run(domainName);
  await domainsDb.close();
}
