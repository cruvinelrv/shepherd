import 'dart:io';
import 'package:shepherd/src/domains/presentation/controllers/microfrontends_controller.dart';

final _controller = MicrofrontendsController();

Future<void> runListMicrofrontendsCommand() async {
  final microfrontends = _controller.loadMicrofrontends();
  if (microfrontends.isEmpty) {
    print('No microfrontends registered.');
  } else {
    print('Registered microfrontends:');
    for (var i = 0; i < microfrontends.length; i++) {
      final m = microfrontends[i];
      print('  ${i + 1}. ${m['name']} (${m['path'] ?? '-'})');
      if (m['description'] != null) print('     ${m['description']}');
    }
  }
}

Future<void> runAddMicrofrontendCommand() async {
  stdout.write('Enter microfrontend name: ');
  final name = stdin.readLineSync()?.trim();
  if (name == null || name.isEmpty) {
    print('Name cannot be empty.');
    return;
  }
  stdout.write('Enter path (relative to project root): ');
  final path = stdin.readLineSync()?.trim();
  stdout.write('Enter description (optional): ');
  final description = stdin.readLineSync()?.trim();
  try {
    _controller.addMicrofrontend(name: name, path: path, description: description);
    print('Microfrontend "$name" added.');
  } catch (e) {
    print(e);
  }
}

Future<void> runRemoveMicrofrontendCommand() async {
  final microfrontends = _controller.loadMicrofrontends();
  if (microfrontends.isEmpty) {
    print('No microfrontends to remove.');
    return;
  }
  print('Registered microfrontends:');
  for (var i = 0; i < microfrontends.length; i++) {
    final m = microfrontends[i];
    print('  ${i + 1}. ${m['name']} (${m['path'] ?? '-'})');
  }
  stdout.write('Enter the number or name of the microfrontend to remove: ');
  final input = stdin.readLineSync()?.trim();
  if (input == null || input.isEmpty) {
    print('No input provided.');
    return;
  }
  final idx = int.tryParse(input);
  try {
    if (idx != null && idx > 0 && idx <= microfrontends.length) {
      _controller.removeMicrofrontendByIndex(idx - 1);
      print('Removed microfrontend: ${microfrontends[idx - 1]['name']}');
    } else {
      _controller.removeMicrofrontendByName(input);
      print('Removed microfrontend: $input');
    }
  } catch (e) {
    print(e);
  }
}
