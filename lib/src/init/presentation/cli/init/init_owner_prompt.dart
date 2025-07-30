import 'package:shepherd/src/menu/presentation/cli/input_utils.dart';
import '../../../../domains/data/datasources/local/domains_database.dart';
import 'init_cancel_exception.dart';
import 'package:shepherd/src/domains/presentation/controllers/add_owner_controller.dart';
import 'package:shepherd/src/domain/usecases/add_owner_usecase.dart';

Future<bool> promptOwners(DomainsDatabase db, String domainName,
    {bool allowCancel = false}) async {
  while (true) {
    final addOwnerController = AddOwnerController(
      AddOwnerUseCase(db),
    );
    try {
      await addOwnerController.run(domainName);
    } on ShepherdInitCancelled {
      // Cancel from within addOwnerController: propagate upwards
      throw ShepherdInitCancelled();
    }
    final addMore = readLinePrompt(
        'Add another owner? (y/n${allowCancel ? "/9 to return to main menu" : ""}): ');
    if (addMore == null) continue;
    if (allowCancel && addMore.trim() == '9') {
      throw ShepherdInitCancelled();
    }
    if (addMore.toLowerCase() != 'y') break;
  }
  return true;
}
