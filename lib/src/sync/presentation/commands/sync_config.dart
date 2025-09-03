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
  SyncFileConfig(path: '.shepherd/feature_toggles.yaml', requiredSync: true),
  SyncFileConfig(path: '.shepherd/config.yaml', requiredSync: true),
  SyncFileConfig(path: '.shepherd/environments.yaml', requiredSync: true),
  SyncFileConfig(path: '.shepherd/project.yaml', requiredSync: true),
  SyncFileConfig(path: '.shepherd/user_active.yaml', requiredSync: true),
  // Example of an optional file:
  // SyncFileConfig(path: '.shepherd/extra.yaml', requiredSync: false),
];
