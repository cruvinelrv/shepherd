import 'package:shepherd/src/menu/presentation/cli/input_utils.dart';
import 'init_cancel_exception.dart';

Future<String?> promptDomainName({bool allowCancel = false}) async {
  String? domainName;
  while (true) {
    domainName = readLinePrompt(
        'Enter the main domain name for this project${allowCancel ? " (9 to return to main menu)" : ""}: ');
    if (domainName == null) continue;
    final trimmed = domainName.trim();
    if (allowCancel && trimmed == '9') {
      throw ShepherdInitCancelled();
    }
    if (trimmed.isEmpty) {
      print('Domain name cannot be empty.');
      continue;
    }
    return trimmed;
  }
}
