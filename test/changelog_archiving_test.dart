import 'package:shepherd/src/tools/domain/entities/changelog_entities.dart';
import 'package:shepherd/src/tools/domain/repositories/i_changelog_repository.dart';
import 'package:shepherd/src/tools/domain/usecases/update_changelog_for_update_usecase.dart';
import 'package:test/test.dart';

class MockChangelogRepository implements IChangelogRepository {
  bool archiveCalled = false;
  bool copyCalled = false;
  bool updateHeaderCalled = false;
  String readContent = '';

  @override
  Future<void> archiveOldChangelog(String projectDir, String content) async {
    archiveCalled = true;
  }

  @override
  Future<void> copyChangelogFromBranch(String projectDir, String baseBranch) async {
    copyCalled = true;
  }

  @override
  Future<String> readChangelog(String projectDir) async {
    return readContent;
  }

  @override
  Future<ProjectVersion> getCurrentVersion(String projectDir) async {
    return ProjectVersion(version: '1.0.0', source: 'pubspec.yaml');
  }

  @override
  Future<void> updateChangelogHeader(String projectDir, String version) async {
    updateHeaderCalled = true;
  }

  // Not relevant for this test
  @override
  Future<List<ChangelogEntry>> getCommits(
      {required String projectDir, required String baseBranch}) async {
    return [];
  }

  @override
  Future<String> getCurrentBranch(String projectDir) async {
    return 'main';
  }

  @override
  Future<List<MicrofrontendConfig>> getMicrofrontends(String projectDir) async {
    return [];
  }

  @override
  Future<bool> isMicrofrontendsProject(String projectDir) async {
    return false;
  }

  @override
  Future<bool> needsUpdate(String projectDir, String newVersion) async {
    return true;
  }

  @override
  Future<void> writeChangelog(String projectDir, String content) async {}
}

void main() {
  group('UpdateChangelogForUpdateUseCase', () {
    test('should archive existing changelog before copying new one', () async {
      final repo = MockChangelogRepository();
      repo.readContent = '# Old Changelog';
      final useCase = UpdateChangelogForUpdateUseCase(repo);

      await useCase.execute(projectDir: '.', baseBranch: 'main');

      expect(repo.archiveCalled, isTrue, reason: 'Should call archiveOldChangelog');
      expect(repo.copyCalled, isTrue, reason: 'Should call copyChangelogFromBranch');
      expect(repo.updateHeaderCalled, isTrue, reason: 'Should call updateChangelogHeader');
    });

    test('should NOT archive if existing changelog is empty', () async {
      final repo = MockChangelogRepository();
      repo.readContent = ''; // Empty
      final useCase = UpdateChangelogForUpdateUseCase(repo);

      await useCase.execute(projectDir: '.', baseBranch: 'main');

      expect(repo.archiveCalled, isFalse, reason: 'Should NOT call archiveOldChangelog if empty');
      expect(repo.copyCalled, isTrue);
    });
  });
}
