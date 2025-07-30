import '../../domain/usecases/delete_domain_usecase.dart';

/// Controller for domain deletion actions.
class DeleteController {
  final DeleteDomainUseCase useCase;
  DeleteController(this.useCase);

  /// Deletes the specified domain and prints a confirmation message.
  Future<void> run(String domainName) async {
    await useCase.deleteDomain(domainName);
    print('Domain "$domainName" deleted successfully!');
  }
}
