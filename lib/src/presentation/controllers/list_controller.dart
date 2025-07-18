import 'package:shepherd/src/domain/usecases/list_usecase.dart';

/// Controller for listing domains and their owners.
class ListController {
  final ListUseCase useCase;
  ListController(this.useCase);

  /// Lists all domains and their owners, printing the results to the user.
  Future<void> run() async {
    final domains = await useCase.getDomainsWithOwners();
    if (domains.isEmpty) {
      print('No domains registered in the project.');
      return;
    }
    print('Registered domains:');
    for (final domain in domains) {
      print('---');
      print('Domain: ${domain['name']}');
      if (domain['owners'] != null && domain['owners'].isNotEmpty) {
        print('Owners:');
        for (final owner in domain['owners']) {
          print('  - ${owner['first_name']} ${owner['last_name']} (${owner['type']})');
        }
      } else {
        print('Owners: No owner registered');
      }
      if (domain['warnings'] != null && domain['warnings'].isNotEmpty) {
        print('Warnings:');
        for (final warning in domain['warnings']) {
          print('  - $warning');
        }
      }
    }
  }
}
