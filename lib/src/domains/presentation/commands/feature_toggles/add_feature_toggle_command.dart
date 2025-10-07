import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/enhanced_feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/enhanced_feature_toggle_entity.dart';

Future<void> runAddFeatureToggleCommand() async {
  print('🚀 Adicionando Feature Toggle\n');

  // Campos obrigatórios
  stdout.write('Nome do Feature Toggle: ');
  final name = stdin.readLineSync() ?? '';

  stdout.write('Habilitado? (y/n): ');
  final enabledInput = stdin.readLineSync()?.toLowerCase() ?? 'n';
  final enabled = enabledInput == 'y' || enabledInput == 's';

  stdout.write('Domínio: ');
  final domain = stdin.readLineSync() ?? '';

  stdout.write('Descrição: ');
  final description = stdin.readLineSync() ?? '';

  // Campos opcionais (empresariais)
  print('\n📋 Campos opcionais (pressione Enter para pular):');

  stdout.write('Equipe: ');
  final team = stdin.readLineSync()?.trim();

  stdout.write('Atividade: ');
  final activity = stdin.readLineSync()?.trim();

  stdout.write('Protótipo: ');
  final prototype = stdin.readLineSync()?.trim();

  stdout.write('Versão mínima: ');
  final minVersion = stdin.readLineSync()?.trim();

  stdout.write('Versão máxima: ');
  final maxVersion = stdin.readLineSync()?.trim();

  // Criar entidade unificada
  final toggle = EnhancedFeatureToggleEntity(
    name: name,
    enabled: enabled,
    domain: domain,
    description: description,
    team: team?.isEmpty == true ? null : team,
    activity: activity?.isEmpty == true ? null : activity,
    prototype: prototype?.isEmpty == true ? null : prototype,
    minVersion: minVersion?.isEmpty == true ? null : minVersion,
    maxVersion: maxVersion?.isEmpty == true ? null : maxVersion,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Salvar no banco aprimorado
  final db = EnhancedFeatureToggleDatabase(Directory.current.path);
  await db.insertFeatureToggle(toggle);

  // Exportar para YAML (usando o sistema existente se disponível)
  try {
    // Tentar usar o exportador existente (pode precisar de adaptação)
    print('💾 Salvando no banco de dados...');
    print('✅ Feature toggle "$name" adicionado com sucesso!');

    if (team != null || activity != null || prototype != null) {
      print('📊 Campos empresariais adicionados: ${[
        team,
        activity,
        prototype
      ].where((e) => e?.isNotEmpty == true).join(', ')}');
    }
  } catch (e) {
    print('⚠️  Feature toggle salvo, mas erro no export: $e');
  }
}
