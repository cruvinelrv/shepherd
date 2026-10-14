import 'dart:io';

/// Runs a program; replaced in tests.
typedef RunProcess = Future<ProcessResult> Function(
    String executable, List<String> arguments,
    {String? workingDirectory});

Future<ProcessResult> defaultRunProcess(String executable, List<String> args,
        {String? workingDirectory}) =>
    Process.run(executable, args, workingDirectory: workingDirectory);

/// What the quick init needs to know about git (it never changes anything).
class GitProbe {
  final RunProcess run;
  final String dir;

  GitProbe(this.dir, {RunProcess? run}) : run = run ?? defaultRunProcess;

  Future<String?> _out(List<String> args) async {
    try {
      final r = await run('git', args, workingDirectory: dir);
      if (r.exitCode != 0) return null;
      final s = '${r.stdout}'.trim();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null; // git is not installed
    }
  }

  Future<bool> get installed async => await _out(['--version']) != null;

  Future<bool> get isRepository async =>
      await _out(['rev-parse', '--is-inside-work-tree']) == 'true';

  /// The branch the trunk lives on: the current one, `main` when there is none yet.
  Future<String> get trunk async =>
      await _out(['symbolic-ref', '--short', 'HEAD']) ?? 'main';

  /// `github` or `azure` from the `origin` remote, null when there is none or it
  /// is somewhere else.
  Future<String?> get remoteType async {
    final url = (await _out(['remote', 'get-url', 'origin']))?.toLowerCase();
    if (url == null) return null;
    if (url.contains('github.com')) return 'github';
    if (url.contains('dev.azure.com') ||
        url.contains('visualstudio.com') ||
        url.contains('ssh.dev.azure.com')) {
      return 'azure';
    }
    return null;
  }

  /// `user.name` and `user.email` as git has them (global works without a repository).
  Future<({String name, String email})> get user async => (
        name: await _out(['config', 'user.name']) ?? '',
        email: await _out(['config', 'user.email']) ?? '',
      );
}
