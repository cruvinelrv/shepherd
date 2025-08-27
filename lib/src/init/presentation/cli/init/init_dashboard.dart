import 'dart:io';

Future<void> cloneDashboard() async {
  print('[cloneDashboard] Diretório atual: ${Directory.current.path}');
  final dashboardDir = Directory('dashboard');
  if (!dashboardDir.existsSync()) {
    print('Cloning dashboard project...');
    final repoUrl = 'https://github.com/cruvinelrv/shepherd_dashboard.git';
    final result = await Process.run('git', ['clone', repoUrl, 'dashboard']);
    if (result.exitCode == 0) {
      print('Dashboard cloned successfully.');
    } else {
      print('Failed to clone dashboard: ${result.stderr}');
    }
  } else {
    print('Dashboard already exists locally.');
  }
}
