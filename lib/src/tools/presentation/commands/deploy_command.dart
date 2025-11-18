import 'dart:io';
import '../../../deploy/presentation/controllers/azure_pr_command.dart';
import '../../../menu/presentation/cli/deploy_menu.dart';
import '../../domain/services/changelog_service.dart';

/// Deploy command handler
Future<void> runDeployCommand(List<String> arguments) async {
  // Always run deploy step by step directly
  await runDeployStepByStep(
    runChangelogCommand: (baseBranch) async {
      // Uses ChangelogService with the provided baseBranch
      final service = ChangelogService();
      final changelogType = await service.cli.promptChangelogType();
      if (changelogType == 'update') {
        // Copies the changelog from the reference branch (using git checkout)
        await service.copyChangelogFromReference(baseBranch, projectDir: Directory.current.path);
        // Updates the header to the specified version
        String? version;
        final pubspecFile = File('pubspec.yaml');
        if (pubspecFile.existsSync()) {
          final lines = pubspecFile.readAsLinesSync();
          final versionLine = lines.firstWhere(
            (l) => l.trim().startsWith('version:'),
            orElse: () => '',
          );
          if (versionLine.isNotEmpty) {
            version = versionLine.split(':').last.trim();
          }
        }
        if (version != null && version.isNotEmpty) {
          await service.updateChangelogHeader(version);
        }
        print('CHANGELOG.md updated to version $version.');
      } else {
        // For change, follows the previous flow
        final updatedPaths =
            await service.updateChangelog(baseBranch: baseBranch, changelogType: changelogType);
        if (updatedPaths.isNotEmpty) {
          print('CHANGELOG.md successfully updated for:');
          for (final path in updatedPaths) {
            print('  - $path');
          }
        } else {
          print('No changes detected or CHANGELOG.md was not updated.');
        }
      }
    },
    runAzureOpenPrCommand: runAzureOpenPrCommand,
  );
}
