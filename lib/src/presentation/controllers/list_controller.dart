import 'package:shepherd/src/domain/usecases/list_usecase.dart';

class ListController {
  final ListUseCase useCase;
  ListController(this.useCase);

  Future<void> run() async {
    final domains = await useCase.getDomainsWithOwners();
    if (domains.isEmpty) {
      print('Nenhum domínio cadastrado no projeto.');
      return;
    }
    print('Domínios cadastrados:');
    for (final domain in domains) {
      print('---');
      print('Domínio: ${domain['name']}');
      if (domain['owners'] != null && domain['owners'].isNotEmpty) {
        print('Owners:');
        for (final owner in domain['owners']) {
          print('  - ${owner['first_name']} ${owner['last_name']} (${owner['type']})');
        }
      } else {
        print('Owners: Nenhum owner cadastrado');
      }
      if (domain['warnings'] != null && domain['warnings'].isNotEmpty) {
        print('Avisos:');
        for (final warning in domain['warnings']) {
          print('  - $warning');
        }
      }
    }
  }
}
