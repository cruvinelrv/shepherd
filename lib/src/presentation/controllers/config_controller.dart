import 'dart:io';
import 'package:shepherd/src/domain/usecases/config_usecase.dart';

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
        stdout.write('Type (e.g., dev, lead, admin): ');
        final type = stdin.readLineSync();

        if (firstName != null && lastName != null && type != null) {
          final ownerId = await useCase.db.insertPerson(
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            type: type.trim(),
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
