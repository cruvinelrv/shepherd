import 'dart:io';
import '../usecases/update_changelog_usecase.dart';
import '../repositories/i_changelog_repository.dart';
import '../../data/repositories/changelog_repository.dart';
import '../../data/datasources/file_changelog_datasource.dart';
import '../../data/datasources/git_datasource.dart';
import '../../data/datasources/pubspec_datasource.dart';
import '../../presentation/cli/changelog_cli.dart';

/// Main changelog service facade - maintains backward compatibility
class ChangelogService {
  late final UpdateChangelogUseCase _updateUseCase;
  late final ChangelogCli _cli;

  ChangelogService() {
    // Initialize dependencies using DDD architecture
    final fileDataSource = FileChangelogDatasource();
    final gitDataSource = GitDatasource();
    final pubspecDataSource = PubspecDatasource(fileDataSource);

    final IChangelogRepository repository = ChangelogRepository(
      fileDataSource,
      gitDataSource,
      pubspecDataSource,
    );

    _updateUseCase = UpdateChangelogUseCase(repository);
    _cli = ChangelogCli();
  }

  /// Updates the project's CHANGELOG.md, maintaining backward compatibility
  Future<List<String>> updateChangelog({
    String? baseBranch,
    String? projectDir,
    List<String>? environments,
  }) async {
    try {
      final dir = projectDir ?? Directory.current.path;
      final branch = baseBranch ?? await _cli.promptBaseBranch();

      final updatedPaths = await _updateUseCase.execute(
        projectDir: dir,
        baseBranch: branch,
      );

      return updatedPaths;
    } catch (e) {
      _cli.showError(e.toString());
      rethrow;
    }
  }
}
