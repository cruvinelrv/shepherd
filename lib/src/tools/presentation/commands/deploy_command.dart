import '../../../deploy/presentation/controllers/azure_pr_command.dart';
import '../../../menu/presentation/cli/deploy_menu.dart';
import '../../domain/services/changelog_service.dart';

/// Deploy command handler
Future<void> runDeployCommand(List<String> arguments) async {
  // Always run deploy step by step directly
  await runDeployStepByStep(
    runChangelogCommand: (baseBranch) async {
      // Create a simple changelog service instance and call it
      final service = ChangelogService();
      await service.updateChangelog(baseBranch: baseBranch);
    },
    runAzureOpenPrCommand: runAzureOpenPrCommand,
  );
}
