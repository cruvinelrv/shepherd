import 'dart:io';

Future<void> runDashboardCommand() async {
  final dashboardDir = Directory('.shepherd/shepherd_dashboard');
  final localDir = Directory.current;
  if (!dashboardDir.existsSync()) {
    print('Dashboard not found. Cloning dashboard project...');
    final repoUrl = 'https://github.com/cruvinelrv/shepherd_dashboard.git';
    final result = await Process.run('git', ['clone', repoUrl, dashboardDir.path]);
    if (result.exitCode == 0) {
      print('Dashboard cloned successfully.');
    } else {
      print('Failed to clone dashboard: ${result.stderr}');
      exit(1);
    }
  } else {
    print('Dashboard already exists locally. Checking for updates...');
    await Process.run('git', ['fetch'], workingDirectory: localDir.path);
    final statusResult =
        await Process.run('git', ['status', '-uno'], workingDirectory: localDir.path);
    if (statusResult.stdout.toString().contains('behind')) {
      print('Updates available for dashboard. Pulling latest changes...');
      final pullResult = await Process.run('git', ['pull'], workingDirectory: localDir.path);
      if (pullResult.exitCode == 0) {
        print('Dashboard updated successfully.');
      } else {
        print('Failed to update dashboard: ${pullResult.stderr}');
      }
    } else {
      print('Dashboard is up to date.');
    }
  }
  print('Abrindo o dashboard Flutter Desktop...');
  String flutterDesktopTarget;
  if (Platform.isMacOS) {
    flutterDesktopTarget = 'macos';
  } else if (Platform.isLinux) {
    flutterDesktopTarget = 'linux';
  } else if (Platform.isWindows) {
    flutterDesktopTarget = 'windows';
  } else {
    print('Sistema operacional não suportado para Flutter Desktop.');
    exit(1);
  }
  if (!dashboardDir.existsSync()) {
    print('Diretório do dashboard não encontrado: .shepherd/shepherd_dashboard');
    exit(1);
  }
  final flutterRun = await Process.start(
    'flutter',
    ['run', '-d', flutterDesktopTarget],
    workingDirectory: dashboardDir.path,
    mode: ProcessStartMode.inheritStdio,
  );
  await flutterRun.exitCode;
  exit(0);
}
