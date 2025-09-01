import 'package:shepherd/src/tools/domain/services/changelog_service.dart';

/// Use case for updating the project changelog.
class ChangelogUseCase {
  final ChangelogService service;
  ChangelogUseCase(this.service);

  /// Updates the project changelog by delegating to the service.
  Future<void> updateChangelog({String? baseBranch}) async {
    await service.updateChangelog(baseBranch: baseBranch);
  }
}
