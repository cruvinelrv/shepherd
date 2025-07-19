import 'dart:io';
import 'input_utils.dart';

Future<String> _getGitRemoteUrl() async {
  final result = await Process.run('git', ['remote', 'get-url', 'origin']);
  if (result.exitCode == 0) {
    return (result.stdout as String).trim();
  }
  return '';
}

Future<String> _getGitCurrentBranch() async {
  final result = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  if (result.exitCode == 0) {
    return (result.stdout as String).trim();
  }
  return '';
}

Future<void> showDeployMenuLoop({
  required Future<void> Function() runChangelogCommand,
  required Future<void> Function(List<String>) runAzureOpenPrCommand,
}) async {
  const magenta = '\x1B[35m';
  const reset = '\x1B[0m';
  while (true) {
    print('\n$magenta================ DEPLOY MENU =================$reset');
    printDeployMenu();
    final input = stdin.readLineSync();
    print('');
    switch (input?.trim()) {
      case '1':
        await runChangelogCommand();
        pauseForEnter();
        break;
      case '2':
        print('Choose PR creation mode:');
        print('  1. Interactive');
        print('  2. Provide arguments directly');
        final mode = readIntOption('Select (1 or 2): ', [1, 2]);
        if (mode == 1) {
          final gitRepo = await _getGitRemoteUrl();
          final gitBranch = await _getGitCurrentBranch();
          final repo = readLinePrompt('Repository name [default: $gitRepo]: ')?.trim();
          final source = readLinePrompt('Source branch [default: $gitBranch]: ')?.trim();
          final target = readNonEmptyInput('Target branch: ');
          final title = readNonEmptyInput('PR title: ');
          final desc = readLinePrompt('Description (optional): ') ?? '';
          await runAzureOpenPrCommand([
            (repo != null && repo.isNotEmpty) ? repo : gitRepo,
            (source != null && source.isNotEmpty) ? source : gitBranch,
            target,
            title,
            desc
          ]);
        } else {
          final args = readNonEmptyInput(
              'Enter arguments: <repo> <source> <target> <title> [description]\n> ');
          await runAzureOpenPrCommand(args.split(' '));
        }
        pauseForEnter();
        break;
      case '0':
        print('\nReturning to main menu...\n');
        return;
      default:
        print('Invalid option. Please try again.');
        pauseForEnter();
    }
    print('\n----------------------------------------------\n');
  }
}

void printDeployMenu() {
  print('''
Shepherd Deploy - Deployment and Release Tools

  1. Update the project CHANGELOG.md
  2. Open Pull Request (Azure CLI)
  0. Back to main menu

Select an option (number):
''');
}
