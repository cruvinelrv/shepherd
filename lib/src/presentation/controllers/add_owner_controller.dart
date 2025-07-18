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
      stdout
          .write('Enter the number of the person to add as owner, or "n" to register a new one: ');
      final input = stdin.readLineSync();
      if (input == null || input.trim().isEmpty) {
        print('Operation cancelled.');
        return;
      }
      if (input.trim().toLowerCase() == 'n') {
        // Register new person
        stdout.write('First name: ');
        final firstName = stdin.readLineSync()?.trim() ?? '';
        stdout.write('Last name: ');
        final lastName = stdin.readLineSync()?.trim() ?? '';
        String? type;
        while (type == null || !allowedOwnerTypes.contains(type)) {
          stdout.write('Type (${allowedOwnerTypes.join(", ")}): ');
          type = stdin.readLineSync()?.trim();
        }
        final newId = await useCase.addPerson(firstName, lastName, type);
        personIdToAdd = newId;
        print('Person registered!');
      } else {
        final idx = int.tryParse(input.trim());
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
