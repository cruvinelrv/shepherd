import 'dart:io';
import 'package:shepherd/src/domains/domain/usecases/config_usecase.dart';
import 'package:shepherd/src/utils/owner_types.dart';

/// Controller for configuring domains and their owners.
class ConfigController {
  final ConfigUseCase useCase;
  ConfigController(this.useCase);

  /// Runs the domain registration flow, including owner assignment.
  Future<void> run() async {
    print('--- Domain Registration ---');
    stdout.write('Enter the domain name: ');
    final domainName = stdin.readLineSync();
    if (domainName == null || domainName.trim().isEmpty) {
      print('Invalid domain name.');
      return;
    }

    // Owner registration
    List<int> ownerIds = [];
    stdout.write('Do you want to add owners for this domain? (y/n): ');
    final addOwners = stdin.readLineSync();
    if (addOwners != null && addOwners.toLowerCase() == 'y') {
      while (true) {
        print('--- Owner Registration ---');
        stdout.write('First name: ');
        final firstName = stdin.readLineSync();
        stdout.write('Last name: ');
        final lastName = stdin.readLineSync();
        String? type;
        while (type == null || !allowedOwnerTypes.contains(type)) {
          stdout.write('Type (${allowedOwnerTypes.join(", ")}): ');
          type = stdin.readLineSync()?.trim();
        }

        if (firstName != null && lastName != null) {
          stdout.write('Email: ');
          final email = stdin.readLineSync();
          if (email == null || email.trim().isEmpty) {
            print('Email is required.');
            continue;
          }
          final ownerId = await useCase.configDb.insertPerson(
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            email: email.trim(),
            type: type,
          );
          ownerIds.add(ownerId);
          print('Owner registered!');
        } else {
          print('Invalid data, please try again.');
        }

        stdout.write('Add another owner? (y/n): ');
        final more = stdin.readLineSync();
        if (more == null || more.toLowerCase() != 'y') break;
      }
    }

    // Save the domain only once, already with the owners
    await useCase.addDomain(
      domainName: domainName.trim(),
      score: 0.0,
      commits: 0,
      days: 0,
      warnings: '',
      personIds: ownerIds,
    );
    print('Domain registered successfully!');
    print('Configuration completed!');
  }
}
