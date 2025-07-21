import 'dart:io';

Future<void> runVersionCommand(List<String> args) async {
  final pubspec = File('pubspec.yaml');
  if (await pubspec.exists()) {
    final lines = await pubspec.readAsLines();
    final versionLine = lines.firstWhere(
      (l) => l.trim().startsWith('version:'),
      orElse: () => '',
    );
    if (versionLine.isNotEmpty) {
      final version = versionLine.split(':').last.trim();
      print('shepherd version $version');
    } else {
      print('Version not found in pubspec.yaml');
    }
  } else {
    print('pubspec.yaml not found');
  }
}
