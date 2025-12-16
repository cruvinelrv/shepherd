import 'dart:io';
import '../entities/update_entities.dart';
import '../usecases/check_for_updates_usecase.dart';
import '../../data/repositories/update_repository.dart';
import '../../data/datasources/pub_dev_datasource.dart';
import '../../data/datasources/update_cache_datasource.dart';
import '../../data/datasources/update_config_datasource.dart';
import '../../presentation/cli/update_prompt_cli.dart';

/// Service facade for update checking
class UpdateCheckerService {
  static const String _packageName = 'shepherd';
  static const String _currentVersion = '0.6.8';

  late final CheckForUpdatesUseCase _checkUseCase;
  late final UpdateConfigDatasource _configDatasource;
  late final UpdatePromptCli _promptCli;

  UpdateCheckerService({String? projectPath}) {
    final path = projectPath ?? Directory.current.path;

    // Initialize dependencies
    final pubDevDatasource = PubDevDatasource();
    final cacheDatasource = UpdateCacheDatasource(path);
    final repository = UpdateRepositoryImpl(
      pubDevDatasource,
      cacheDatasource,
    );

    _checkUseCase = CheckForUpdatesUseCase(
      repository,
      _packageName,
      _currentVersion,
    );

    _configDatasource = UpdateConfigDatasource(path);
    _promptCli = UpdatePromptCli();
  }

  /// Check for updates and handle based on configuration mode
  /// Returns the update check result
  Future<UpdateCheckResult> checkAndHandle() async {
    // Check environment variable to skip update check
    if (Platform.environment['SHEPHERD_SKIP_UPDATE_CHECK'] == '1') {
      return UpdateCheckResult.skipped();
    }

    // Load configuration
    final config = await _configDatasource.getUpdateConfig();

    // If silent mode, skip check
    if (config.mode == UpdateMode.silent) {
      return UpdateCheckResult.skipped();
    }

    // Check for updates
    final result = await _checkUseCase.execute();

    if (!result.updateAvailable || result.version == null) {
      return result;
    }

    // Handle based on mode
    switch (config.mode) {
      case UpdateMode.notify:
        // Just show notification (handled by caller)
        break;

      case UpdateMode.prompt:
        // Prompt user and potentially execute update
        await _handlePromptMode(result.version!);
        break;

      case UpdateMode.silent:
        // Already handled above
        break;
    }

    return result;
  }

  /// Handle prompt mode - ask user and execute update if confirmed
  Future<void> _handlePromptMode(PackageVersionEntity version) async {
    final changelogUrl = _getChangelogUrl(version.latest);
    final shouldUpdate = _promptCli.promptForUpdate(
      version.current,
      version.latest,
      changelogUrl,
    );

    if (shouldUpdate) {
      await _executeUpdate(version.latest);
    }
  }

  /// Execute the update command
  Future<void> _executeUpdate(String version) async {
    try {
      _promptCli.displayUpdating();

      final result = await Process.run(
        'dart',
        ['pub', 'global', 'activate', _packageName],
      );

      if (result.exitCode == 0) {
        _promptCli.displaySuccess(version);
      } else {
        _promptCli.displayError(result.stderr.toString());
      }
    } catch (e) {
      _promptCli.displayError(e.toString());
    }
  }

  /// Get changelog URL for a version
  String _getChangelogUrl(String version) {
    return 'https://pub.dev/packages/$_packageName/changelog#${version.replaceAll('.', '')}';
  }

  /// Format the update notification message (for notify mode)
  String formatUpdateNotification(UpdateCheckResult result) {
    if (!result.updateAvailable || result.version == null) {
      return '';
    }

    final version = result.version!;
    final changelogUrl = _getChangelogUrl(version.latest);

    return '''
╭──────────────────────────────────────────────────────────────╮
│ 📦 Update available: ${version.current} → ${version.latest}${' ' * (18 - version.current.length - version.latest.length)}│
│                                                              │
│ Run: dart pub global activate $_packageName${' ' * (27 - _packageName.length)}│
│                                                              │
│ 📋 What's new? $changelogUrl │
╰──────────────────────────────────────────────────────────────╯''';
  }
}
