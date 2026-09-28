import 'package:shepherd/src/tools/data/models/git_remote_repo_model.dart';

/// Helper for detecting and parsing Git remote URLs (GitHub and Azure DevOps).
class GitRemoteHelper {
  /// Detects whether a remote is 'github' or 'azure', prioritizing [configuredType] if provided.
  static String? detectRepoType(String remoteUrl, {String? configuredType}) {
    if (configuredType != null && configuredType.trim().isNotEmpty) {
      final norm = configuredType.trim().toLowerCase();
      if (norm == 'github' || norm == 'azure') return norm;
    }

    final lower = remoteUrl.toLowerCase();
    if (lower.contains('dev.azure.com') ||
        lower.contains('visualstudio.com') ||
        lower.contains('ssh.dev.azure.com')) {
      return 'azure';
    }
    if (lower.contains('github.com')) {
      return 'github';
    }
    return null;
  }

  /// Parses a GitHub remote URL into a [GitHubRepoModel].
  static GitHubRepoModel? parseGitHubRepo(String url) {
    String clean = url.trim();
    if (clean.endsWith('.git')) clean = clean.substring(0, clean.length - 4);

    if (clean.contains('github.com')) {
      final idx = clean.indexOf('github.com');
      final after = clean.substring(idx + 'github.com'.length);
      final trimmed = after.startsWith(':') || after.startsWith('/')
          ? after.substring(1)
          : after;
      final parts = trimmed.split('/');
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return GitHubRepoModel(owner: parts[0], repository: parts[1]);
      }
    }
    return null;
  }

  /// Parses an Azure DevOps remote URL into an [AzureRepoModel].
  static AzureRepoModel? parseAzureRepo(String url) {
    String clean = url.trim();
    if (clean.endsWith('.git')) clean = clean.substring(0, clean.length - 4);

    // SSH format: git@ssh.dev.azure.com:v3/{org}/{project}/{repo}
    if (clean.contains('ssh.dev.azure.com')) {
      final v3Idx = clean.indexOf('v3/');
      if (v3Idx != -1) {
        final parts = clean.substring(v3Idx + 3).split('/');
        if (parts.length >= 3 &&
            parts[0].isNotEmpty &&
            parts[1].isNotEmpty &&
            parts[2].isNotEmpty) {
          return AzureRepoModel(
            organization: parts[0],
            project: parts[1],
            repository: parts[2],
          );
        }
      }
    }

    // HTTPS formats: dev.azure.com or visualstudio.com
    final uri = Uri.tryParse(clean);
    if (uri != null && uri.host.isNotEmpty) {
      final host = uri.host.toLowerCase();
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      if (host.contains('visualstudio.com')) {
        final org = host.split('.visualstudio.com').first;
        final gitIdx = segments.indexOf('_git');
        if (gitIdx > 0 && gitIdx + 1 < segments.length) {
          final proj = segments[gitIdx - 1];
          final repo = segments[gitIdx + 1];
          if (org.isNotEmpty && proj.isNotEmpty && repo.isNotEmpty) {
            return AzureRepoModel(
              organization: org,
              project: proj,
              repository: repo,
            );
          }
        }
      } else if (host.contains('dev.azure.com')) {
        final gitIdx = segments.indexOf('_git');
        if (gitIdx >= 2 && gitIdx + 1 < segments.length) {
          final org = segments[gitIdx - 2];
          final proj = segments[gitIdx - 1];
          final repo = segments[gitIdx + 1];
          if (org.isNotEmpty && proj.isNotEmpty && repo.isNotEmpty) {
            return AzureRepoModel(
              organization: org,
              project: proj,
              repository: repo,
            );
          }
        }
      }
    }

    return null;
  }
}
