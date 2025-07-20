import 'package:shepherd/src/presentation/cli/input_utils.dart';
import 'package:shepherd/src/presentation/controllers/add_owner_controller.dart';
import 'package:shepherd/src/domain/usecases/add_owner_usecase.dart';

import '../../data/datasources/local/shepherd_database.dart';

Future<void> promptOwners(ShepherdDatabase db, String domainName) async {
  while (true) {
    final addOwnerController = AddOwnerController(
      AddOwnerUseCase(db),
    );
    await addOwnerController.run(domainName);
    final addMore = readLinePrompt('Add another owner? (y/n): ');
    if (addMore == null || addMore.toLowerCase() != 'y') break;
  }
}
