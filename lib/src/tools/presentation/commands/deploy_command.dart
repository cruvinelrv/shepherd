import '../../../deploy/presentation/controllers/azure_pr_command.dart';
import '../../../menu/presentation/cli/deploy_menu.dart';
import '../../domain/services/changelog_service.dart';

/// Deploy command handler
Future<void> runDeployCommand(List<String> arguments) async {
  // Always run deploy step by step directly
  await runDeployStepByStep(
    runChangelogCommand: (baseBranch) async {
      // Use the ChangelogService with the provided baseBranch
      final service = ChangelogService();
      final updatedPaths = await service.updateChangelog(baseBranch: baseBranch);

      if (updatedPaths.isNotEmpty) {
        print('CHANGELOG.md successfully updated for:');
        for (final path in updatedPaths) {
          print('  - $path');
        }
      } else {
        print('No changes detected or CHANGELOG.md was not updated.');
      }
    },
    runAzureOpenPrCommand: runAzureOpenPrCommand,
  );
}
