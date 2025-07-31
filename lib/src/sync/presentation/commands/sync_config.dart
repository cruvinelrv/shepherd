class SyncFileConfig {
  /// Relative path of the monitored YAML file.
  final String path;

  /// Whether synchronization of this file is required for Shepherd to start normally.
  final bool requiredSync;

  const SyncFileConfig({required this.path, this.requiredSync = true});
}

/// List of files synchronized with the Shepherd database.
/// Add or remove files as needed.
const List<SyncFileConfig> syncedFiles = [
  SyncFileConfig(
      path: 'dev_tools/shepherd/feature_toggles.yaml', requiredSync: true),
  SyncFileConfig(path: 'dev_tools/shepherd/config.yaml', requiredSync: true),
  SyncFileConfig(
      path: 'dev_tools/shepherd/environments.yaml', requiredSync: true),
  SyncFileConfig(path: 'dev_tools/shepherd/project.yaml', requiredSync: true),
  // Example of an optional file:
  // SyncFileConfig(path: 'dev_tools/shepherd/extra.yaml', requiredSync: false),
];
