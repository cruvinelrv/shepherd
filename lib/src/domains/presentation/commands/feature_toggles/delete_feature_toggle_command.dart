import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/enhanced_feature_toggle_database.dart';

Future<void> runDeleteFeatureToggleCommand() async {
  print('🗑️ Excluindo Feature Toggle\n');

  final db = EnhancedFeatureToggleDatabase(Directory.current.path);

  // Mostrar lista de feature toggles para o usuário escolher
  final toggles = await db.getAllFeatureToggles();

  if (toggles.isEmpty) {
    print('❌ Nenhum feature toggle encontrado.');
    print('💡 Use o comando "Add Feature Toggle" para criar o primeiro.');
    return;
  }

  print('📋 Feature Toggles disponíveis:');
  for (final toggle in toggles) {
    final status = toggle.enabled ? '✅' : '❌';
    print('   $status [${toggle.id}] ${toggle.name} - ${toggle.domain}');
    if (toggle.description.isNotEmpty) {
      print('      ${toggle.description}');
    }
  }

  stdout.write('\nDigite o ID do feature toggle para excluir: ');
  final idInput = stdin.readLineSync();
  final id = int.tryParse(idInput ?? '');

  if (id == null) {
    print('❌ ID inválido.');
    return;
  }

  // Buscar o feature toggle existente
  final existingToggle = toggles.where((t) => t.id == id).firstOrNull;
  if (existingToggle == null) {
    print('❌ Feature toggle com ID $id não encontrado.');
    return;
  }

  // Mostrar detalhes e confirmar exclusão
  print('\n🔍 Feature Toggle a ser excluído:');
  print('   ID: ${existingToggle.id}');
  print('   Nome: ${existingToggle.name}');
  print('   Status: ${existingToggle.enabled ? 'Habilitado' : 'Desabilitado'}');
  print('   Domínio: ${existingToggle.domain}');
  print('   Descrição: ${existingToggle.description}');
  if (existingToggle.team != null) print('   Equipe: ${existingToggle.team}');
  if (existingToggle.activity != null)
    print('   Atividade: ${existingToggle.activity}');

  stdout.write(
      '\n⚠️ Tem certeza que deseja excluir este feature toggle? (y/N): ');
  final confirmation = stdin.readLineSync()?.toLowerCase().trim();

  if (confirmation != 'y' &&
      confirmation != 'yes' &&
      confirmation != 's' &&
      confirmation != 'sim') {
    print('❌ Operação cancelada.');
    return;
  }

  // Excluir do banco
  await db.deleteFeatureToggleById(id);

  print('\n✅ Feature toggle "${existingToggle.name}" excluído com sucesso!');
}
