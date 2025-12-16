abstract class UpdateRepository {
  /// Get the latest version from pub.dev
  Future<String?> getLatestVersion(String packageName);

  /// Get the last time an update check was performed
  Future<DateTime?> getLastCheckTime();

  /// Save the timestamp of the last update check
  Future<void> saveLastCheckTime(DateTime time);
}
