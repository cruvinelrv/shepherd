import '../entities/update_entities.dart';
import '../repositories/update_repository.dart';

/// Use case for checking for package updates
class CheckForUpdatesUseCase {
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  final UpdateRepository _repository;
  final String _packageName;
  final String _currentVersion;

  CheckForUpdatesUseCase(
    this._repository,
    this._packageName,
    this._currentVersion,
  );

  /// Execute the update check
  /// Returns UpdateCheckResult with information about available updates
  Future<UpdateCheckResult> execute() async {
    try {
      // Check if we should skip the check based on cache
      final lastCheck = await _repository.getLastCheckTime();
      if (lastCheck != null) {
        final timeSinceLastCheck = DateTime.now().difference(lastCheck);
        if (timeSinceLastCheck < _cacheValidityDuration) {
          // Cache is still valid, skip check
          return UpdateCheckResult.skipped();
        }
      }

      // Fetch latest version from pub.dev
      final latestVersion = await _repository.getLatestVersion(_packageName);

      if (latestVersion == null) {
        // Failed to fetch, but don't treat as error (silent fail)
        return UpdateCheckResult.skipped();
      }

      // Save the check timestamp
      await _repository.saveLastCheckTime(DateTime.now());

      // Create version object
      final version = PackageVersionEntity(
        current: _currentVersion,
        latest: latestVersion,
      );

      // Check if update is available
      if (version.hasUpdate) {
        return UpdateCheckResult.updateAvailable(version);
      } else {
        return UpdateCheckResult.noUpdate(version);
      }
    } catch (e) {
      // Any error should be silently ignored
      return UpdateCheckResult.error(e.toString());
    }
  }
}
