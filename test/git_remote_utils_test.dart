import 'dart:io';
import 'package:test/test.dart';
import 'package:shepherd/src/utils/git_remote_utils.dart';
import 'package:shepherd/src/utils/config_utils.dart';

void main() {
  group('GitRemoteHelper Tests', () {
    test('detectRepoType prioritizes configuredType from .shepherd/config.yaml', () {
      final detected = GitRemoteHelper.detectRepoType(
        'https://github.com/marmelotech/shepherd.git',
        configuredType: 'azure',
      );
      expect(detected, equals('azure'));

      final detectedGh = GitRemoteHelper.detectRepoType(
        'https://dev.azure.com/myorg/myproject/_git/myrepo',
        configuredType: 'github',
      );
      expect(detectedGh, equals('github'));
    });

    test('detectRepoType infers azure from dev.azure.com, visualstudio.com and ssh', () {
      expect(
        GitRemoteHelper.detectRepoType('https://dev.azure.com/org/proj/_git/repo'),
        equals('azure'),
      );
      expect(
        GitRemoteHelper.detectRepoType('https://myorg.visualstudio.com/proj/_git/repo'),
        equals('azure'),
      );
      expect(
        GitRemoteHelper.detectRepoType('git@ssh.dev.azure.com:v3/org/proj/repo'),
        equals('azure'),
      );
    });

    test('detectRepoType infers github from github.com URLs', () {
      expect(
        GitRemoteHelper.detectRepoType('https://github.com/owner/repo.git'),
        equals('github'),
      );
      expect(
        GitRemoteHelper.detectRepoType('git@github.com:owner/repo.git'),
        equals('github'),
      );
    });

    test('parseGitHubRepo correctly extracts owner and repository', () {
      final repo = GitRemoteHelper.parseGitHubRepo('https://github.com/marmelotech/shepherd.git');
      expect(repo, isNotNull);
      expect(repo!.owner, equals('marmelotech'));
      expect(repo.repository, equals('shepherd'));
      expect(repo.fullName, equals('marmelotech/shepherd'));
      expect(
        repo.prWebUrl('release/v1.0.0', 'main'),
        equals('https://github.com/marmelotech/shepherd/compare/main...release/v1.0.0'),
      );
    });

    test('parseAzureRepo correctly extracts organization, project, repository from dev.azure.com', () {
      final repo = GitRemoteHelper.parseAzureRepo(
        'https://dev.azure.com/marmelotech/CoreApp/_git/shepherd-cli.git',
      );
      expect(repo, isNotNull);
      expect(repo!.organization, equals('marmelotech'));
      expect(repo.project, equals('CoreApp'));
      expect(repo.repository, equals('shepherd-cli'));
      expect(
        repo.prWebUrl('release/v1.0.0', 'main'),
        equals(
          'https://dev.azure.com/marmelotech/CoreApp/_git/shepherd-cli/pullrequestcreate?sourceRef=release/v1.0.0&targetRef=main',
        ),
      );
      expect(
        repo.restApiPrUrl,
        equals(
          'https://dev.azure.com/marmelotech/CoreApp/_apis/git/repositories/shepherd-cli/pullrequests?api-version=7.1',
        ),
      );
    });

    test('parseAzureRepo parses visualstudio.com and SSH formats', () {
      final vsRepo = GitRemoteHelper.parseAzureRepo(
        'https://marmelotech.visualstudio.com/DefaultCollection/CoreApp/_git/shepherd-cli',
      );
      expect(vsRepo, isNotNull);
      expect(vsRepo!.organization, equals('marmelotech'));
      expect(vsRepo.project, equals('CoreApp'));
      expect(vsRepo.repository, equals('shepherd-cli'));

      final sshRepo = GitRemoteHelper.parseAzureRepo(
        'git@ssh.dev.azure.com:v3/marmelotech/CoreApp/shepherd-cli',
      );
      expect(sshRepo, isNotNull);
      expect(sshRepo!.organization, equals('marmelotech'));
      expect(sshRepo.project, equals('CoreApp'));
      expect(sshRepo.repository, equals('shepherd-cli'));
    });
  });

  group('config_utils getRepoType & isPullRequestEnabled', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('shepherd_config_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('reads repoType and pullRequestEnabled from .shepherd/config.yaml', () {
      final shepherdDir = Directory('${tempDir.path}/.shepherd')..createSync(recursive: true);
      File('${shepherdDir.path}/config.yaml').writeAsStringSync('''
repoType: azure
pullRequestEnabled: false
''');

      expect(getRepoType(projectPath: tempDir.path), equals('azure'));
      expect(isPullRequestEnabled(projectPath: tempDir.path), isFalse);
    });

    test('defaults to null and true when file is absent', () {
      expect(getRepoType(projectPath: tempDir.path), isNull);
      expect(isPullRequestEnabled(projectPath: tempDir.path), isTrue);
    });
  });
}
