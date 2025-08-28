import 'dart:io';
import 'package:shepherd/src/utils/shepherd_config_default.dart';

/// Displays debug information about Shepherd's essential files.
void debugEssentialFiles() {
  for (final f in essentialShepherdFiles) {
    final file = File(f);
    print(
        '[DEBUG] $f: exists=${file.existsSync()} length=${file.existsSync() ? file.lengthSync() : 'N/A'}');
  }
}
