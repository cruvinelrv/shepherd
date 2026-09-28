/// Entity representing a remote Git repository.
abstract class GitRemoteRepoEntity {
  final String repository;

  const GitRemoteRepoEntity({required this.repository});

  /// Web URL for creating or comparing Pull Requests in the browser.
  String prWebUrl(String sourceBranch, String targetBranch);

  /// REST API endpoint for creating Pull Requests programmatically.
  String get restApiPrUrl;
}

/// Entity representing a GitHub repository (owner/repository).
class GitHubRepoEntity extends GitRemoteRepoEntity {
  final String owner;

  const GitHubRepoEntity({
    required this.owner,
    required super.repository,
  });

  String get fullName => '$owner/$repository';

  @override
  String prWebUrl(String sourceBranch, String targetBranch) =>
      'https://github.com/$owner/$repository/compare/$targetBranch...$sourceBranch';

  @override
  String get restApiPrUrl =>
      'https://api.github.com/repos/$owner/$repository/pulls';
}

/// Entity representing an Azure DevOps repository (organization/project/repository).
class AzureRepoEntity extends GitRemoteRepoEntity {
  final String organization;
  final String project;

  const AzureRepoEntity({
    required this.organization,
    required this.project,
    required super.repository,
  });

  String get orgUrl => 'https://dev.azure.com/$organization';

  @override
  String prWebUrl(String sourceBranch, String targetBranch) =>
      'https://dev.azure.com/$organization/$project/_git/$repository/pullrequestcreate?sourceRef=$sourceBranch&targetRef=$targetBranch';

  @override
  String get restApiPrUrl =>
      'https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository/pullrequests?api-version=7.1';
}
