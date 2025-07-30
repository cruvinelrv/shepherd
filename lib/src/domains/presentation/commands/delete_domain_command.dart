import 'package:shepherd/src/domains/presentation/controllers/delete_controller.dart';
import 'package:shepherd/src/utils/owner_utils.dart';

import '../../domain/usecases/delete_domain_usecase.dart';

Future<void> runDeleteCommand(String domainName) async {
  final domainsDb = openDomainsDb();
  final useCase = DeleteDomainUseCase(domainsDb);
  final controller = DeleteController(useCase);
  await controller.run(domainName);
  await domainsDb.close();
}
