import 'package:shepherd/src/domain/services/changelog_service.dart';

/// Use case for updating the project changelog.
class ChangelogUseCase {
  final ChangelogService service;
  ChangelogUseCase(this.service);

  /// Updates the project changelog by delegating to the service.
  Future<void> updateChangelog() async {
    await service.updateChangelog();
  }
}
