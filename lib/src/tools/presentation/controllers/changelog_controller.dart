import 'package:shepherd/src/tools/domain/usecases/changelog_usecase.dart';

class ChangelogController {
  final ChangelogUseCase useCase;
  ChangelogController(this.useCase);

  Future<void> run() async {
    await useCase.updateChangelog();
  }
}
