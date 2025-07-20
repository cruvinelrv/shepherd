import '../cli/init/init_cancel_exception.dart';
import 'dart:io';
import 'package:shepherd/src/domain/usecases/add_owner_usecase.dart';
import 'package:shepherd/src/utils/owner_types.dart';

/// Controller for adding owners to domains.
class AddOwnerController {
  final AddOwnerUseCase useCase;
  AddOwnerController(this.useCase);

  /// Runs the flow to add an owner to the specified domain.
  Future<void> run(String domainName) async {
    // Show current owners
    final owners = await useCase.getOwnersForDomain(domainName);
    print('Current owners of domain "$domainName":');
    if (owners.isEmpty) {
      print('  (none)');
    } else {
      for (final o in owners) {
        print('  - ${o['first_name']} ${o['last_name']} (${o['type']})');
      }
    }

    // Show registered persons
    final persons = await useCase.getAllPersons();
    if (persons.isNotEmpty) {
      print('Registered persons:');
      for (var i = 0; i < persons.length; i++) {
        final p = persons[i];
        print('  [${i + 1}] ${p['first_name']} ${p['last_name']} (${p['type']})');
      }
    } else {
      print('No persons registered yet.');
    }

    int? personIdToAdd;
    while (personIdToAdd == null) {
      stdout.write(
          'Enter the number of the person to add as owner, or "n" to register a new one (9 to return to main menu): ');
      final input = stdin.readLineSync();
      if (input == null || input.trim().isEmpty) {
        print('Operation cancelled.');
        return;
      }
      final trimmed = input.trim().toLowerCase();
      if (trimmed == '9') {
        throw ShepherdInitCancelled();
      }
      if (trimmed == 'n') {
        // Register new person
        stdout.write('First name (or 9 to return to main menu): ');
        final firstName = stdin.readLineSync()?.trim() ?? '';
        if (firstName == '9') throw ShepherdInitCancelled();
        stdout.write('Last name (or 9 to return to main menu): ');
        final lastName = stdin.readLineSync()?.trim() ?? '';
        if (lastName == '9') throw ShepherdInitCancelled();
        stdout.write('E-mail (or 9 to return to main menu): ');
        final email = stdin.readLineSync()?.trim() ?? '';
        if (email == '9') throw ShepherdInitCancelled();
        String? type;
        while (type == null || !allowedOwnerTypes.contains(type)) {
          stdout.write('Type (${allowedOwnerTypes.join(", ")}) (or 9 to return to main menu): ');
          type = stdin.readLineSync()?.trim();
          if (type == '9') throw ShepherdInitCancelled();
        }
        stdout.write('GitHub username (opcional, ou 9 para voltar ao menu principal): ');
        final githubUsername = stdin.readLineSync()?.trim();
        if (githubUsername == '9') throw ShepherdInitCancelled();
        final newId = await useCase.addPerson(firstName, lastName, email, type, githubUsername);
        personIdToAdd = newId;
        print('Person registered!');
      } else {
        final idx = int.tryParse(trimmed);
        if (idx != null && idx > 0 && idx <= persons.length) {
          final pid = persons[idx - 1]['id'] as int;
          if (owners.any((o) => o['id'] == pid)) {
            print('This person is already an owner of this domain.');
          } else {
            personIdToAdd = pid;
          }
        } else {
          print('Invalid input.');
        }
      }
    }

    await useCase.addOwnerToDomain(domainName, personIdToAdd);
    print('Person added as owner of domain "$domainName"!');
  }
}
