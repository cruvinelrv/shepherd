import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/domains/presentation/commands/feature_toggles/import_field_configuration.dart';

/// Comando para configurar campos de importação de feature toggles
Future<void> runConfigureImportFieldsCommand() async {
  print('🔧 Configuração de Campos de Importação');
  print('=' * 50);
  print('Configure como os campos do seu DynamoDB/Terraform');
  print('devem ser mapeados para o Shepherd.\n');

  while (true) {
    print('Opções:');
    print('1. Usar configuração pré-definida');
    print('2. Criar configuração personalizada');
    print('3. Visualizar configurações existentes');
    print('4. Exportar configuração atual');
    print('5. Importar configuração de arquivo');
    print('6. Voltar');

    stdout.write('\nEscolha uma opção (1-6): ');
    final option = stdin.readLineSync()?.trim() ?? '6';

    switch (option) {
      case '1':
        await _usePredefinedConfiguration();
        break;
      case '2':
        await _createCustomConfiguration();
        break;
      case '3':
        await _viewExistingConfigurations();
        break;
      case '4':
        await _exportConfiguration();
        break;
      case '5':
        await _importConfiguration();
        break;
      case '6':
        return;
      default:
        print('❌ Opção inválida. Tente novamente.');
    }

    print('\n${'=' * 50}');
  }
}

Future<void> _usePredefinedConfiguration() async {
  print('\n📋 Configurações Pré-definidas:');

  final configs = PredefinedConfigurations.allConfigurations;
  for (int i = 0; i < configs.length; i++) {
    final config = configs[i];
    print('${i + 1}. ${config.configName} (v${config.version})');
    print('   ${config.description}');
    print('   📊 ${config.fieldMappings.length} campos mapeados');
  }

  stdout.write('\nEscolha uma configuração (1-${configs.length}): ');
  final choice = stdin.readLineSync()?.trim();

  if (choice == null || choice.isEmpty) {
    print('❌ Opção inválida.');
    return;
  }

  final index = int.tryParse(choice);
  if (index == null || index < 1 || index > configs.length) {
    print('❌ Opção inválida.');
    return;
  }

  final selectedConfig = configs[index - 1];
  await _saveConfiguration(selectedConfig);

  print('\n✅ Configuração "${selectedConfig.configName}" aplicada com sucesso!');
  print('📁 Arquivo salvo em: .shepherd/import_config.yaml');
}

Future<void> _createCustomConfiguration() async {
  print('\n🛠️  Criando Configuração Personalizada');

  stdout.write('Nome da configuração: ');
  final name = stdin.readLineSync()?.trim() ?? '';

  stdout.write('Versão (ex: 1.0.0): ');
  final version = stdin.readLineSync()?.trim() ?? '1.0.0';

  stdout.write('Descrição: ');
  final description = stdin.readLineSync()?.trim() ?? '';

  final fieldMappings = <FeatureToggleFieldConfig>[];

  print('\n📋 Agora vamos configurar os campos:');
  print('(Digite "fim" quando terminar de adicionar campos)');

  while (true) {
    print('\n--- Novo Campo ---');

    stdout.write('Nome do campo no DynamoDB (ex: name, status): ');
    final dynamoField = stdin.readLineSync()?.trim() ?? '';

    if (dynamoField.toLowerCase() == 'fim') break;
    if (dynamoField.isEmpty) continue;

    stdout.write('Nome do campo no Shepherd (ex: name, enabled): ');
    final shepherdField = stdin.readLineSync()?.trim() ?? dynamoField;

    print('Tipo do campo:');
    print('1. String (texto)');
    print('2. Number (número)');
    print('3. Boolean (verdadeiro/falso)');
    print('4. String Array (lista de textos)');
    print('5. Number Array (lista de números)');

    stdout.write('Escolha o tipo (1-5): ');
    final typeChoice = stdin.readLineSync()?.trim() ?? '1';

    final fieldType = switch (typeChoice) {
      '2' => FeatureToggleFieldType.number,
      '3' => FeatureToggleFieldType.boolean,
      '4' => FeatureToggleFieldType.stringArray,
      '5' => FeatureToggleFieldType.numberArray,
      _ => FeatureToggleFieldType.string,
    };

    stdout.write('É obrigatório? (s/n): ');
    final isRequired = stdin.readLineSync()?.trim().toLowerCase() == 's';

    stdout.write('Valor padrão (deixe vazio se não houver): ');
    final defaultValue = stdin.readLineSync()?.trim();

    stdout.write('Descrição do campo: ');
    final fieldDescription = stdin.readLineSync()?.trim();

    fieldMappings.add(FeatureToggleFieldConfig(
      dynamoFieldName: dynamoField,
      shepherdFieldName: shepherdField,
      fieldType: fieldType,
      isRequired: isRequired,
      defaultValue: defaultValue?.isNotEmpty == true ? defaultValue : null,
      description: fieldDescription?.isNotEmpty == true ? fieldDescription : null,
    ));

    print('✅ Campo "$dynamoField" adicionado!');
  }

  if (fieldMappings.isEmpty) {
    print('❌ Nenhum campo foi configurado.');
    return;
  }

  final config = ImportConfiguration(
    configName: name,
    version: version,
    description: description,
    fieldMappings: fieldMappings,
  );

  await _saveConfiguration(config);

  print('\n✅ Configuração personalizada criada com sucesso!');
  print('📊 ${fieldMappings.length} campos configurados');
  print('📁 Arquivo salvo em: .shepherd/import_config.yaml');
}

Future<void> _viewExistingConfigurations() async {
  print('\n👀 Configurações Existentes:');

  // Show predefined configurations
  print('\n📋 Pré-definidas:');
  for (final config in PredefinedConfigurations.allConfigurations) {
    print('\n🏷️  ${config.configName} (v${config.version})');
    print('   📝 ${config.description}');
    print('   📊 ${config.fieldMappings.length} campos:');

    for (final field in config.fieldMappings.take(5)) {
      final required = field.isRequired ? ' (obrigatório)' : '';
      print('     • ${field.dynamoFieldName} → ${field.shepherdFieldName}$required');
    }

    if (config.fieldMappings.length > 5) {
      print('     ... e mais ${config.fieldMappings.length - 5} campos');
    }
  }

  // Show current configuration if exists
  final currentConfig = await _loadCurrentConfiguration();
  if (currentConfig != null) {
    print('\n📁 Configuração Atual:');
    print('🏷️  ${currentConfig.configName} (v${currentConfig.version})');
    print('   📝 ${currentConfig.description}');
    print('   📊 ${currentConfig.fieldMappings.length} campos configurados');
  }
}

Future<void> _exportConfiguration() async {
  final currentConfig = await _loadCurrentConfiguration();

  if (currentConfig == null) {
    print('❌ Nenhuma configuração ativa encontrada.');
    return;
  }

  stdout.write('Caminho para salvar o arquivo de configuração: ');
  final filePath = stdin.readLineSync()?.trim();

  if (filePath == null || filePath.isEmpty) {
    print('❌ Caminho inválido.');
    return;
  }

  try {
    final file = File(filePath);
    final yamlStr = currentConfig.toYamlString();
    await file.writeAsString(yamlStr);

    print('✅ Configuração exportada para: $filePath');
  } catch (e) {
    print('❌ Erro ao exportar configuração: $e');
  }
}

Future<void> _importConfiguration() async {
  stdout.write('Caminho do arquivo de configuração: ');
  final filePath = stdin.readLineSync()?.trim();

  if (filePath == null || filePath.isEmpty) {
    print('❌ Caminho inválido.');
    return;
  }

  final file = File(filePath);
  if (!await file.exists()) {
    print('❌ Arquivo não encontrado: $filePath');
    return;
  }

  try {
    final content = await file.readAsString();
    final yamlData = loadYaml(content);
    final config = ImportConfiguration.fromYaml(Map<String, dynamic>.from(yamlData));

    await _saveConfiguration(config);

    print('✅ Configuração importada com sucesso!');
    print('🏷️  ${config.configName} (v${config.version})');
    print('📊 ${config.fieldMappings.length} campos configurados');
  } catch (e) {
    print('❌ Erro ao importar configuração: $e');
  }
}

Future<void> _saveConfiguration(ImportConfiguration config) async {
  final shepherdDir = Directory('.shepherd');
  if (!await shepherdDir.exists()) {
    await shepherdDir.create(recursive: true);
  }

  final configFile = File('.shepherd/import_config.yaml');
  final yamlStr = config.toYamlString();
  await configFile.writeAsString(yamlStr);
}

Future<ImportConfiguration?> _loadCurrentConfiguration() async {
  final configFile = File('.shepherd/import_config.yaml');

  if (!await configFile.exists()) {
    return null;
  }

  try {
    final content = await configFile.readAsString();
    final yamlData = loadYaml(content);
    return ImportConfiguration.fromYaml(Map<String, dynamic>.from(yamlData));
  } catch (e) {
    print('⚠️  Erro ao carregar configuração: $e');
    return null;
  }
}
