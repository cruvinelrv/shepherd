import 'dart:io';
import 'package:shepherd/src/menu/presentation/cli/input_utils.dart';
import 'package:shepherd/src/tools/data/datasources/update_config_datasource.dart';
import 'package:shepherd/src/tools/domain/entities/update_entities.dart';
import 'package:shepherd/src/utils/ansi_colors.dart';

/// Command to configure auto-update settings
Future<void> runAutoUpdateCommand(List<String> args) async {
  final datasource = UpdateConfigDatasource(Directory.current.path);

  // Check if mode is passed as argument
  // Ex: shepherd auto-update --mode=prompt
  // Simple parsing since we don't have full args parser for sub-commands here yet
  String? modeArg;
  for (final arg in args) {
    if (arg.startsWith('--mode=')) {
      modeArg = arg.split('=')[1];
    }
  }

  if (modeArg != null) {
    // Direct mode
    final newMode = UpdateMode.fromString(modeArg);
    await datasource.saveUpdateConfig(UpdateConfig(mode: newMode));
    print(
        '${AnsiColors.green}Auto-update mode set to: ${newMode.name}${AnsiColors.reset}');
    return;
  }

  // Interactive mode
  print('\n${AnsiColors.yellow}Auto-Update Configuration${AnsiColors.reset}');

  final currentConfig = await datasource.getUpdateConfig();

  print(
      'Current mode: ${AnsiColors.brightGreen}${currentConfig.mode.name}${AnsiColors.reset}');
  print('\nAvailable modes:');
  print(
      '  1. ${AnsiColors.bold}notify${AnsiColors.reset} (default) - Only show notification when update is available');
  print(
      '  2. ${AnsiColors.bold}prompt${AnsiColors.reset} - Show notification and ask to update automatically');
  print(
      '  3. ${AnsiColors.bold}silent${AnsiColors.reset} - Disable update checks completely');
  print('  0. Cancel');

  final input = readNonEmptyInput('\nSelect new mode (1-3): ');

  UpdateMode? newMode;
  switch (input.trim()) {
    case '1':
      newMode = UpdateMode.notify;
      break;
    case '2':
      newMode = UpdateMode.prompt;
      break;
    case '3':
      newMode = UpdateMode.silent;
      break;
    case '0':
      print('Operation cancelled.');
      return;
    default:
      print('Invalid option.');
      return;
  }

  await datasource.saveUpdateConfig(UpdateConfig(mode: newMode));
  print(
      '\n${AnsiColors.green}Auto-update mode set to: ${newMode.name}${AnsiColors.reset}');
}
