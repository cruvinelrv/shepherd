import 'dart:io';
import 'package:shepherd/src/data/datasources/local/shepherd_database.dart';

/// Controller para editar dados de uma pessoa/owner
class EditPersonController {
  final ShepherdDatabase db;
  EditPersonController(this.db);

  Future<void> run() async {
    final persons = await db.getAllPersons();
    if (persons.isEmpty) {
      print('Nenhuma pessoa cadastrada.');
      return;
    }
    print('Pessoas cadastradas:');
    for (var i = 0; i < persons.length; i++) {
      final p = persons[i];
      print(
          '  [${i + 1}] ${p['first_name']} ${p['last_name']} <${p['email']}> (${p['type']})${p['github_username'] != null && (p['github_username'] as String).isNotEmpty ? ' [GitHub: ${p['github_username']}]' : ''}');
    }
    stdout.write('Digite o número da pessoa que deseja editar: ');
    final input = stdin.readLineSync();
    final idx = int.tryParse(input ?? '');
    if (idx == null || idx < 1 || idx > persons.length) {
      print('Entrada inválida.');
      return;
    }
    final person = persons[idx - 1];
    print(
        'Editando: ${person['first_name']} ${person['last_name']} <${person['email']}>');
    stdout.write('Novo GitHub username (deixe em branco para manter): ');
    final newGithub = stdin.readLineSync()?.trim();
    if (newGithub == null || newGithub.isEmpty) {
      print('Nada alterado.');
      return;
    }
    await db.updatePersonGithubUsername(person['id'] as int, newGithub);
    print('GitHub username atualizado com sucesso!');
  }
}
