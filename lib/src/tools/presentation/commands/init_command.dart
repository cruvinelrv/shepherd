import '../../../init/presentation/cli/init_controller.dart';

/// Initialize command implementation
Future<void> runInitCommand(List<String> args) async {
  final controller = InitController();
  await controller.handleInit();
}
