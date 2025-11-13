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
      final isMicrofrontends = await _repository.isMicrofrontendsProject(projectDir);
      if (isMicrofrontends) {
        final microfrontends = await _repository.getMicrofrontends(projectDir);
        for (final mf in microfrontends) {
          final mfPath = '$projectDir/${mf.path}';
          await _copyAndUpdateHeader(mfPath, baseBranch);
          updatedPaths.add(mfPath);
        }
      } else {
        await _copyAndUpdateHeader(projectDir, baseBranch);
        updatedPaths.add(projectDir);
      }
      return updatedPaths;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _copyAndUpdateHeader(String projectDir, String baseBranch) async {
    // Copy the changelog from the reference branch
    await _repository.copyChangelogFromBranch(projectDir, baseBranch);
    // Update the changelog header to the current version
    final version = await _repository.getCurrentVersion(projectDir);
    await _repository.updateChangelogHeader(projectDir, version.version);
    print('Changelog updated for $projectDir (update branch, no commit lookup)');
  }
}
