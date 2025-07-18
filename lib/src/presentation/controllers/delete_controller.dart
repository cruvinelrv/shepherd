import 'package:shepherd/src/domain/usecases/delete_usecase.dart';

/// Controller for domain deletion actions.
class DeleteController {
  final DeleteUseCase useCase;
  DeleteController(this.useCase);

  /// Deletes the specified domain and prints a confirmation message.
  Future<void> run(String domainName) async {
    await useCase.deleteDomain(domainName);
    print('Domain "$domainName" deleted successfully!');
  }
}
