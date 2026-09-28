import '../../domain/entities/git_remote_repo_entity.dart';

/// Data model representing a GitHub repository.
class GitHubRepoModel extends GitHubRepoEntity {
  const GitHubRepoModel({
    required super.owner,
    required super.repository,
  });

  Map<String, dynamic> toMap() => {
        'owner': owner,
        'repository': repository,
        'type': 'github',
      };

  factory GitHubRepoModel.fromMap(Map<String, dynamic> map) => GitHubRepoModel(
        owner: map['owner']?.toString() ?? '',
        repository: map['repository']?.toString() ?? '',
      );
}

/// Data model representing an Azure DevOps repository.
class AzureRepoModel extends AzureRepoEntity {
  const AzureRepoModel({
    required super.organization,
    required super.project,
    required super.repository,
  });

  Map<String, dynamic> toMap() => {
        'organization': organization,
        'project': project,
        'repository': repository,
        'type': 'azure',
      };

  factory AzureRepoModel.fromMap(Map<String, dynamic> map) => AzureRepoModel(
        organization: map['organization']?.toString() ?? '',
        project: map['project']?.toString() ?? '',
        repository: map['repository']?.toString() ?? '',
      );
}
