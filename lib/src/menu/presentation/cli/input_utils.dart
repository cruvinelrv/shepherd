import 'dart:io';

/// Prints a prompt and reads a line from stdin.
String? readLinePrompt(String prompt) {
  stdout.write(prompt);
  return stdin.readLineSync();
}

/// Reads a non-empty input from the user, showing a prompt until a valid input is given.
String readNonEmptyInput(String prompt) {
  while (true) {
    final input = readLinePrompt(prompt);
    if (input != null && input.trim().isNotEmpty) return input.trim();
    print('Input cannot be empty. Please try again.');
  }
}

/// Reads an integer option from the user, ensuring it is in the list of valid options.
int readIntOption(String prompt, List<int> validOptions) {
  while (true) {
    final input = readLinePrompt(prompt);
    final value = int.tryParse(input ?? '');
    if (value != null && validOptions.contains(value)) return value;
    print('Invalid option. Please enter one of: ${validOptions.join(', ')}');
  }
}

/// Pauses execution until the user presses Enter.
void pauseForEnter([String message = 'Press Enter to continue...']) {
  stdout.write(message);
  stdin.readLineSync();
}
