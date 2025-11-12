import 'dart:io';
import '../usecases/update_changelog_for_change_usecase.dart';
import '../usecases/update_changelog_for_update_usecase.dart';
import '../repositories/i_changelog_repository.dart';
import '../../data/repositories/changelog_repository.dart';
import '../../data/datasources/file_changelog_datasource.dart';
import '../../data/datasources/git_datasource.dart';
import '../../data/datasources/pubspec_datasource.dart';
import '../../presentation/cli/changelog_cli.dart';

/// Main changelog service facade - maintains backward compatibility
class ChangelogService {
  late final UpdateChangelogForChangeUseCase _changeUseCase;
  late final UpdateChangelogForUpdateUseCase _updateUseCase;
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

    _changeUseCase = UpdateChangelogForChangeUseCase(repository);
    _updateUseCase = UpdateChangelogForUpdateUseCase(repository);
    _cli = ChangelogCli();
  }

  /// Updates the project's CHANGELOG.md, maintaining backward compatibility
  Future<List<String>> updateChangelog({
    String? baseBranch,
    String? projectDir,
    List<String>? environments,
  }) async {
    try {
      final changelogType = await _cli.promptChangelogType();
      final dir = projectDir ?? Directory.current.path;
      final branch = baseBranch ?? await _cli.promptBaseBranch();
      if (changelogType == 'update') {
        await _cli.ensureChangelogFromReference(referenceBranch: branch);
        // NÃO atualiza/incrementa cabeçalho do changelog aqui, só copia o changelog.md da branch de referência
        return await _updateUseCase.execute(
          projectDir: dir,
          baseBranch: branch,
        );
      } else {
        // Para tipo 'change', não atualiza/incrementa cabeçalho do changelog
        return await _changeUseCase.execute(
          projectDir: dir,
          baseBranch: branch,
        );
      }
    } catch (e) {
      _cli.showError(e.toString());
      rethrow;
    }
  }
}
