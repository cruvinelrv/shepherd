import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/feature_toggle_database.dart';
import 'package:shepherd/src/domains/data/datasources/local/enhanced_feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/enhanced_feature_toggle_entity.dart';
import 'package:shepherd/src/menu/presentation/cli/input_utils.dart';

Future<void> runListFeatureTogglesCommand() async {
  print('📋 Listando Feature Toggles\n');

  // Tentar carregar do sistema aprimorado primeiro
  final enhancedDb = EnhancedFeatureToggleDatabase(Directory.current.path);
  final enhancedToggles = await enhancedDb.getAllFeatureToggles();

  // Also load from basic system for migration
  final basicDb = FeatureToggleDatabase(Directory.current.path);
  List<dynamic> basicToggles = [];
  try {
    basicToggles = await basicDb.getAllFeatureToggles();
  } catch (e) {
    // Sistema básico pode não existir, tudo bem
  }

  // Display statistics
  print('📊 Estatísticas:');
  print('   Sistema Aprimorado: ${enhancedToggles.length} feature toggles');
  print('   Sistema Básico: ${basicToggles.length} feature toggles');

  if (enhancedToggles.isEmpty && basicToggles.isEmpty) {
    print('\n❌ Nenhum feature toggle encontrado.');
    print('💡 Use o comando "Add Feature Toggle" para criar o primeiro.');
    pauseForEnter();
    return;
  }

  // Show visualization options
  print('\nOpções de listagem:');
  print('1. Todos os feature toggles (aprimorado)');
  print('2. Por domínio');
  print('3. Por equipe');
  print('4. Apenas habilitados');
  print('5. Apenas desabilitados');
  if (basicToggles.isNotEmpty) {
    print('6. Feature toggles do sistema básico (para migração)');
  }

  stdout.write('\nEscolha uma opção (1-${basicToggles.isNotEmpty ? 6 : 5}): ');
  final option = stdin.readLineSync()?.trim() ?? '1';

  switch (option) {
    case '1':
      _displayEnhancedToggles(enhancedToggles, 'Todos os Feature Toggles');
      break;

    case '2':
      stdout.write('Digite o domínio: ');
      final domain = stdin.readLineSync()?.trim() ?? '';
      final filtered = enhancedToggles
          .where((t) => t.domain.toLowerCase().contains(domain.toLowerCase()))
          .toList();
      _displayEnhancedToggles(filtered, 'Feature Toggles - Domínio: $domain');
      break;

    case '3':
      stdout.write('Digite a equipe: ');
      final team = stdin.readLineSync()?.trim() ?? '';
      final filtered = enhancedToggles
          .where((t) => t.team?.toLowerCase().contains(team.toLowerCase()) == true)
          .toList();
      _displayEnhancedToggles(filtered, 'Feature Toggles - Equipe: $team');
      break;

    case '4':
      final enabled = enhancedToggles.where((t) => t.enabled).toList();
      _displayEnhancedToggles(enabled, 'Feature Toggles Habilitados');
      break;

    case '5':
      final disabled = enhancedToggles.where((t) => !t.enabled).toList();
      _displayEnhancedToggles(disabled, 'Feature Toggles Desabilitados');
      break;

    case '6':
      if (basicToggles.isNotEmpty) {
        _displayBasicToggles(basicToggles);
        print('\n💡 Para migrar estes dados para o sistema aprimorado, use a opção de migração.');
      }
      break;

    default:
      print('Opção inválida.');
  }

  pauseForEnter();
}

void _displayEnhancedToggles(List<EnhancedFeatureToggleEntity> toggles, String title) {
  print('\n🎯 $title:');

  if (toggles.isEmpty) {
    print('   Nenhum feature toggle encontrado com os critérios especificados.');
    return;
  }

  for (final toggle in toggles) {
    final status = toggle.enabled ? '✅' : '❌';
    print('\n$status [${toggle.id}] ${toggle.name}');
    print('   Domínio: ${toggle.domain}');
    print('   Status: ${toggle.enabled ? 'Habilitado' : 'Desabilitado'}');
    print('   Descrição: ${toggle.description}');

    // Campos empresariais (se preenchidos)
    if (toggle.team != null) print('   Equipe: ${toggle.team}');
    if (toggle.activity != null) print('   Atividade: ${toggle.activity}');
    if (toggle.prototype != null) print('   Protótipo: ${toggle.prototype}');
    if (toggle.minVersion != null) print('   Versão Min: ${toggle.minVersion}');
    if (toggle.maxVersion != null) print('   Versão Max: ${toggle.maxVersion}');
    if (toggle.createdAt != null) {
      print('   Criado: ${toggle.createdAt!.toLocal().toString().split('.')[0]}');
    }
  }
}

void _displayBasicToggles(List<dynamic> toggles) {
  print('\n⚠️  Feature Toggles do Sistema Básico (Migração Necessária):');

  for (final toggle in toggles) {
    final status = toggle.enabled ? '✅' : '❌';
    print('\n$status [${toggle.id}] ${toggle.name}');
    print('   Domínio: ${toggle.domain}');
    print('   Status: ${toggle.enabled ? 'Habilitado' : 'Desabilitado'}');
    print('   Descrição: ${toggle.description}');
  }
}
