import 'dart:io';

void main() async {
  stdout.write('Enter the base branch (e.g., main, develop): ');
  String? baseBranch = stdin.readLineSync();
  if (baseBranch == null || baseBranch.isEmpty) {
    print('Base branch not provided.');
    return;
  }
  String userName = '';
  try {
    final userResult = await Process.run('git', ['config', 'user.name']);
    if (userResult.exitCode == 0) {
      userName = userResult.stdout.toString().trim();
    }
  } catch (e) {
    print('Error getting user.name: $e');
    return;
  }
  try {
    final result = await Process.run(
      'bash',
      [
        '-c',
        "git log --no-merges --pretty=format:'%h %s [%an, %ad]' --date=short --author='$userName' \$(git merge-base HEAD $baseBranch)..HEAD | grep -E '^[a-f0-9]+ (refactor:|feat:|fix:)' -i"
      ],
      workingDirectory: Directory.current.path,
    );
    print('\n[DEBUG] Raw output from git command:');
    print(result.stdout);
    print('[DEBUG] Código de saída do comando git: ${result.exitCode}');
    if (result.exitCode != 0) {
      print('[DEBUG] Erro: ${result.stderr}');
    }
    if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
      print('\nCommits extracted for changelog:');
      print(result.stdout.toString().trim());
    } else {
      print('No commits found or error during execution.');
    }
  } catch (e) {
    print('[DEBUG] Exception while running git command: $e');
  }
}
