import 'package:shepherd/src/domain/usecases/delete_usecase.dart';

class DeleteController {
  final DeleteUseCase useCase;
  DeleteController(this.useCase);

  Future<void> run(String domainName) async {
    await useCase.deleteDomain(domainName);
    print('Domínio "$domainName" deletado com sucesso!');
  }
}
