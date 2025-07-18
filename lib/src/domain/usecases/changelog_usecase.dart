import 'package:shepherd/src/domain/services/changelog_service.dart';

class ChangelogUseCase {
  final ChangelogService service;
  ChangelogUseCase(this.service);

  Future<void> updateChangelog() async {
    await service.updateChangelog();
  }
}
