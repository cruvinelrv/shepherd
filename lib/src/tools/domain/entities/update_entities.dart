/// Represents a package version
class PackageVersionEntity {
  final String current;
  final String latest;

  const PackageVersionEntity({
    required this.current,
    required this.latest,
  });

  /// Check if an update is available
  bool get hasUpdate => current != latest;

  @override
  String toString() => 'PackageVersion(current: $current, latest: $latest)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageVersionEntity &&
          runtimeType == other.runtimeType &&
          current == other.current &&
          latest == other.latest;

  @override
  int get hashCode => current.hashCode ^ latest.hashCode;
}

/// Result of an update check
class UpdateCheckResult {
  final bool checked;
  final bool updateAvailable;
  final PackageVersionEntity? version;
  final String? error;

  const UpdateCheckResult({
    required this.checked,
    required this.updateAvailable,
    this.version,
    this.error,
  });

  /// Factory for successful check with no update
  factory UpdateCheckResult.noUpdate(PackageVersionEntity version) {
    return UpdateCheckResult(
      checked: true,
      updateAvailable: false,
      version: version,
    );
  }

  /// Factory for successful check with update available
  factory UpdateCheckResult.updateAvailable(PackageVersionEntity version) {
    return UpdateCheckResult(
      checked: true,
      updateAvailable: true,
      version: version,
    );
  }

  /// Factory for check that was skipped (cache)
  factory UpdateCheckResult.skipped() {
    return const UpdateCheckResult(
      checked: false,
      updateAvailable: false,
    );
  }

  /// Factory for failed check
  factory UpdateCheckResult.error(String error) {
    return UpdateCheckResult(
      checked: true,
      updateAvailable: false,
      error: error,
    );
  }

  @override
  String toString() =>
      'UpdateCheckResult(checked: $checked, updateAvailable: $updateAvailable, version: $version, error: $error)';
}

/// Update mode configuration
enum UpdateMode {
  /// Only show notification, no interaction
  notify,

  /// Show notification and prompt user to update
  prompt,

  /// Disable update checks completely
  silent;

  /// Parse from string value
  static UpdateMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'notify':
        return UpdateMode.notify;
      case 'prompt':
        return UpdateMode.prompt;
      case 'silent':
        return UpdateMode.silent;
      default:
        return UpdateMode.notify; // default to notify
    }
  }
}

/// Update configuration
class UpdateConfig {
  final UpdateMode mode;

  const UpdateConfig({required this.mode});

  /// Default configuration
  factory UpdateConfig.defaultConfig() {
    return const UpdateConfig(mode: UpdateMode.notify);
  }

  /// Parse from YAML map
  factory UpdateConfig.fromYaml(Map<String, dynamic>? yaml) {
    if (yaml == null || yaml['auto_update'] == null) {
      return UpdateConfig.defaultConfig();
    }

    final autoUpdateConfig = yaml['auto_update'] as Map<String, dynamic>?;
    if (autoUpdateConfig == null || autoUpdateConfig['mode'] == null) {
      return UpdateConfig.defaultConfig();
    }

    final mode = UpdateMode.fromString(autoUpdateConfig['mode'] as String);
    return UpdateConfig(mode: mode);
  }

  /// Convert to YAML map (to merge with existing config)
  Map<String, dynamic> toYaml() {
    return {
      'mode': mode.name,
    };
  }

  @override
  String toString() => 'UpdateConfig(mode: $mode)';
}
