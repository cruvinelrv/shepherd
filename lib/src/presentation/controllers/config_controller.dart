import 'dart:io';
import 'package:shepherd/src/domain/usecases/config_usecase.dart';

class ConfigController {
  final ConfigUseCase useCase;
  ConfigController(this.useCase);

  Future<void> run() async {
    print('--- Cadastro de Domínio ---');
    stdout.write('Digite o nome do domínio: ');
    final domainName = stdin.readLineSync();
    if (domainName == null || domainName.trim().isEmpty) {
      print('Nome de domínio inválido.');
      return;
    }

    // Cadastro de owners
    List<int> ownerIds = [];
    stdout.write('Deseja adicionar owners para esse domínio? (s/n): ');
    final addOwners = stdin.readLineSync();
    if (addOwners != null && addOwners.toLowerCase() == 's') {
      while (true) {
        print('--- Cadastro de Owner ---');
        stdout.write('Primeiro nome: ');
        final firstName = stdin.readLineSync();
        stdout.write('Último nome: ');
        final lastName = stdin.readLineSync();
        stdout.write('Tipo (ex: dev, lead, admin): ');
        final type = stdin.readLineSync();

        if (firstName != null && lastName != null && type != null) {
          final ownerId = await useCase.db.insertPerson(
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            type: type.trim(),
          );
          ownerIds.add(ownerId);
          print('Owner cadastrado!');
        } else {
          print('Dados inválidos, tente novamente.');
        }

        stdout.write('Adicionar outro owner? (s/n): ');
        final more = stdin.readLineSync();
        if (more == null || more.toLowerCase() != 's') break;
      }
    }

    // Salva o domínio apenas uma vez, já com os owners
    await useCase.addDomain(
      domainName: domainName.trim(),
      score: 0.0,
      commits: 0,
      days: 0,
      warnings: '',
      personIds: ownerIds,
    );
    print('Domínio cadastrado com sucesso!');
    print('Configuração finalizada!');
  }
}
