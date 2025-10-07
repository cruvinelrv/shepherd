import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/enhanced_feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/enhanced_feature_toggle_entity.dart';

Future<void> runEditFeatureToggleCommand() async {
  print('✏️ Editando Feature Toggle\n');

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
  }

  stdout.write('\nDigite o ID do feature toggle para editar: ');
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

  print('\n🔍 Feature Toggle atual:');
  print('   Nome: ${existingToggle.name}');
  print('   Status: ${existingToggle.enabled ? 'Habilitado' : 'Desabilitado'}');
  print('   Domínio: ${existingToggle.domain}');
  print('   Descrição: ${existingToggle.description}');
  if (existingToggle.team != null) print('   Equipe: ${existingToggle.team}');
  if (existingToggle.activity != null)
    print('   Atividade: ${existingToggle.activity}');

  print('\n📝 Digite os novos valores (pressione Enter para manter o atual):');

  // Campos obrigatórios
  stdout.write('Nome [${existingToggle.name}]: ');
  final nameInput = stdin.readLineSync()?.trim();
  final name = nameInput?.isNotEmpty == true ? nameInput! : existingToggle.name;

  stdout.write('Habilitado? (y/n) [${existingToggle.enabled ? 'y' : 'n'}]: ');
  final enabledInput = stdin.readLineSync()?.toLowerCase().trim();
  bool enabled;
  if (enabledInput?.isNotEmpty == true) {
    enabled = enabledInput == 'y' || enabledInput == 's';
  } else {
    enabled = existingToggle.enabled;
  }

  stdout.write('Domínio [${existingToggle.domain}]: ');
  final domainInput = stdin.readLineSync()?.trim();
  final domain =
      domainInput?.isNotEmpty == true ? domainInput! : existingToggle.domain;

  stdout.write('Descrição [${existingToggle.description}]: ');
  final descriptionInput = stdin.readLineSync()?.trim();
  final description = descriptionInput?.isNotEmpty == true
      ? descriptionInput!
      : existingToggle.description;

  // Campos opcionais (empresariais)
  stdout.write('Equipe [${existingToggle.team ?? 'não definido'}]: ');
  final teamInput = stdin.readLineSync()?.trim();
  final team = teamInput?.isNotEmpty == true ? teamInput : existingToggle.team;

  stdout.write('Atividade [${existingToggle.activity ?? 'não definido'}]: ');
  final activityInput = stdin.readLineSync()?.trim();
  final activity = activityInput?.isNotEmpty == true
      ? activityInput
      : existingToggle.activity;

  stdout.write('Protótipo [${existingToggle.prototype ?? 'não definido'}]: ');
  final prototypeInput = stdin.readLineSync()?.trim();
  final prototype = prototypeInput?.isNotEmpty == true
      ? prototypeInput
      : existingToggle.prototype;

  // Criar entidade atualizada
  final updatedToggle = EnhancedFeatureToggleEntity(
    id: existingToggle.id,
    name: name,
    enabled: enabled,
    domain: domain,
    description: description,
    team: team,
    activity: activity,
    prototype: prototype,
    ignoreDocs: existingToggle.ignoreDocs,
    ignoreBundleNames: existingToggle.ignoreBundleNames,
    blockBundleNames: existingToggle.blockBundleNames,
    minVersion: existingToggle.minVersion,
    maxVersion: existingToggle.maxVersion,
    createdAt: existingToggle.createdAt,
    updatedAt: DateTime.now(),
  );

  // Salvar no banco
  await db.updateFeatureToggleById(id, updatedToggle);

  print('\n✅ Feature toggle "$name" atualizado com sucesso!');
}
