import 'dart:io';

/// File operations datasource
class FileChangelogDatasource {
  /// Read file content
  Future<String> readFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return '';
    }
    return file.readAsString();
  }

  /// Write file content
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Check if file exists
  bool fileExists(String path) {
    return File(path).existsSync();
  }

  /// Create directory if it doesn't exist
  Future<void> createDirectory(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
  }
}
