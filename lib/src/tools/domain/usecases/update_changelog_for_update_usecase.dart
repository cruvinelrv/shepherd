import '../repositories/i_changelog_repository.dart';

/// Use case for updating changelog for update branches (version bump, release, etc.)
class UpdateChangelogForUpdateUseCase {
  final IChangelogRepository _repository;

  UpdateChangelogForUpdateUseCase(this._repository);

  /// Execute changelog update for update branches: just copy changelog from reference and update header
  Future<List<String>> execute({
    required String projectDir,
    required String baseBranch,
  }) async {
    final updatedPaths = <String>[];
    try {
      // Always update only the root changelog, even for microfrontends
      await _copyAndUpdateHeader(projectDir, baseBranch);
      updatedPaths.add(projectDir);
      return updatedPaths;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _copyAndUpdateHeader(
      String projectDir, String baseBranch) async {
    // Archive existing changelog before overwriting
    final existingChangelog = await _repository.readChangelog(projectDir);
    if (existingChangelog.isNotEmpty) {
      await _repository.archiveOldChangelog(projectDir, existingChangelog);
      print('Archived existing changelog to dev_tools/changelog_history.md');
    }

    // Copy the changelog from the reference branch
    await _repository.copyChangelogFromBranch(projectDir, baseBranch);
    // Update the changelog header to the current version
    final version = await _repository.getCurrentVersion(projectDir);
    await _repository.updateChangelogHeader(projectDir, version.version);
    print(
        'Changelog updated for $projectDir (update branch, no commit lookup)');
  }
}
