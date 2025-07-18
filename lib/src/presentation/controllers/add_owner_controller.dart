import 'dart:io';
import 'package:shepherd/src/domain/usecases/add_owner_usecase.dart';

class AddOwnerController {
  final AddOwnerUseCase useCase;
  AddOwnerController(this.useCase);

  Future<void> run(String domainName) async {
    // Exibe owners atuais
    final owners = await useCase.getOwnersForDomain(domainName);
    print('Owners atuais do domínio "$domainName":');
    if (owners.isEmpty) {
      print('  (nenhum)');
    } else {
      for (final o in owners) {
        print('  - ${o['first_name']} ${o['last_name']} (${o['type']})');
      }
    }

    // Exibe pessoas cadastradas
    final persons = await useCase.getAllPersons();
    if (persons.isNotEmpty) {
      print('Pessoas já cadastradas:');
      for (var i = 0; i < persons.length; i++) {
        final p = persons[i];
        print('  [${i + 1}] ${p['first_name']} ${p['last_name']} (${p['type']})');
      }
    } else {
      print('Nenhuma pessoa cadastrada ainda.');
    }

    int? personIdToAdd;
    while (personIdToAdd == null) {
      stdout.write(
          'Digite o número da pessoa para adicionar como owner, ou "n" para cadastrar nova: ');
      final input = stdin.readLineSync();
      if (input == null || input.trim().isEmpty) {
        print('Operação cancelada.');
        return;
      }
      if (input.trim().toLowerCase() == 'n') {
        // Cadastro de nova pessoa
        stdout.write('Primeiro nome: ');
        final firstName = stdin.readLineSync()?.trim() ?? '';
        stdout.write('Sobrenome: ');
        final lastName = stdin.readLineSync()?.trim() ?? '';
        String? type;
        while (type == null || !['administrator', 'developer', 'lead_domain'].contains(type)) {
          stdout.write('Tipo (administrator, developer, lead_domain): ');
          type = stdin.readLineSync()?.trim();
        }
        final newId = await useCase.addPerson(firstName, lastName, type);
        personIdToAdd = newId;
        print('Pessoa cadastrada!');
      } else {
        final idx = int.tryParse(input.trim());
        if (idx != null && idx > 0 && idx <= persons.length) {
          final pid = persons[idx - 1]['id'] as int;
          if (owners.any((o) => o['id'] == pid)) {
            print('Essa pessoa já é owner deste domínio.');
          } else {
            personIdToAdd = pid;
          }
        } else {
          print('Entrada inválida.');
        }
      }
    }

    await useCase.addOwnerToDomain(domainName, personIdToAdd);
    print('Pessoa adicionada como owner do domínio "$domainName"!');
  }
}
