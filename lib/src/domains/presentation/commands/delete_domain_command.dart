import 'package:shepherd/src/domains/domain/usecases/delete_doa_usecase.dart';
import 'package:shepherd/src/domains/presentation/controllers/delete_controller.dart';
import 'package:shepherd/src/utils/owner_utils.dart';

Future<void> runDeleteCommand(String domainName) async {
  final domainsDb = openDomainsDb();
  final useCase = DeleteDomainUseCase(domainsDb);
  final controller = DeleteController(useCase);
  await controller.run(domainName);
  await domainsDb.close();
}
