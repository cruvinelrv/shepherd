import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/domains/data/datasources/local/enhanced_feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/enhanced_feature_toggle_entity.dart';
import 'package:shepherd/src/domains/presentation/commands/feature_toggles/import_field_configuration.dart';
import 'package:shepherd/src/domains/presentation/commands/feature_toggles/import_dynamodb_command.dart';

/// Comando para importação dinâmica de feature toggles baseado na configuração
Future<void> runDynamicImportCommand() async {
  print('🔄 Importação: Terraform DynamoDB → Shepherd');
  print('=' * 50);

  // Carregar configuração
  final config = await _loadImportConfiguration();
  if (config == null) {
    print('❌ Nenhuma configuração de importação encontrada.');
    print('💡 Execute primeiro: Configure Import Fields (opção 5)');
    return;
  }

  print('📋 Usando configuração: ${config.configName} (v${config.version})');
  print('📊 ${config.fieldMappings.length} campos configurados\n');

  // Solicitar arquivo
  stdout.write('Caminho do arquivo Terraform (.tf): ');
  final filePath = stdin.readLineSync()?.trim();

  if (filePath == null || filePath.isEmpty) {
    print('❌ Caminho do arquivo é obrigatório');
    return;
  }

  final file = File(filePath);
  if (!await file.exists()) {
    print('❌ Arquivo não encontrado: $filePath');
    return;
  }

  print('\n🔍 Analisando arquivo Terraform (.tf)...');
  print('📋 Usando configuração YAML salva para mapear campos...');

  try {
    // Ler e processar arquivo
    final content = await file.readAsString();
    final items = await _parseTerraformContent(content, config);

    if (items.isEmpty) {
      print('❌ Nenhum item DynamoDB encontrado no arquivo');
      return;
    }

    print('✅ ${items.length} feature toggles encontrados');

    // Confirmar importação
    stdout.write(
        '\n❓ Deseja importar estes ${items.length} feature toggles? (s/n): ');
    final confirm = stdin.readLineSync()?.trim().toLowerCase();

    if (confirm != 's' && confirm != 'sim') {
      print('❌ Importação cancelada');
      return;
    }

    // Importar para o database
    print('\n📦 Importando feature toggles...');
    final database = EnhancedFeatureToggleDatabase(Directory.current.path);

    int imported = 0;
    int errors = 0;

    for (final item in items) {
      try {
        await database.insertFeatureToggle(item);
        imported++;

        if (imported % 10 == 0) {
          print('   📊 $imported/${items.length} importados...');
        }
      } catch (e) {
        errors++;
        print('   ⚠️  Erro ao importar ${item.name}: $e');
      }
    }

    // Exibir resultados
    print('\n📊 Resultado da Importação:');
    print('✅ Importados com sucesso: $imported');
    if (errors > 0) {
      print('❌ Erros: $errors');
    }

    if (imported > 0) {
      // Exportar YAML automaticamente
      stdout.write('\n❓ Deseja exportar para YAML? (s/n): ');
      final exportYaml = stdin.readLineSync()?.trim().toLowerCase();

      if (exportYaml == 's' || exportYaml == 'sim') {
        print('\n📄 Exportando para YAML...');
        await exportEnhancedFeatureTogglesToYaml(
            database, Directory.current.path);
        print('✅ Arquivo YAML atualizado!');
      }
    }
  } catch (e) {
    print('❌ Erro durante a importação: $e');
  }
}

Future<ImportConfiguration?> _loadImportConfiguration() async {
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

Future<List<EnhancedFeatureToggleEntity>> _parseTerraformContent(
    String content, ImportConfiguration config) async {
  final items = <EnhancedFeatureToggleEntity>[];

  // Regex para encontrar recursos DynamoDB
  final resourceRegex = RegExp(
    r'resource\s+"aws_dynamodb_table_item"\s+"([^"]+)"\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}',
    multiLine: true,
    dotAll: true,
  );

  final matches = resourceRegex.allMatches(content);

  for (final match in matches) {
    try {
      final resourceName = match.group(1)!;
      final resourceBody = match.group(2)!;

      // Extrair o JSON do item
      final itemRegex =
          RegExp(r'item\s*=\s*<<JSON\s*(.*?)\s*JSON', dotAll: true);
      final itemMatch = itemRegex.firstMatch(resourceBody);

      if (itemMatch != null) {
        final jsonString = itemMatch.group(1)!.trim();
        final itemData = jsonDecode(jsonString);

        // Converter usando a configuração
        final toggle =
            await _convertToEnhancedToggle(resourceName, itemData, config);

        if (toggle != null) {
          items.add(toggle);
        }
      }
    } catch (e) {
      print('⚠️  Erro ao processar item: $e');
    }
  }

  return items;
}

Future<EnhancedFeatureToggleEntity?> _convertToEnhancedToggle(
  String resourceName,
  Map<String, dynamic> itemData,
  ImportConfiguration config,
) async {
  try {
    // Mapear campos básicos
    final mappedData = <String, dynamic>{};

    for (final fieldConfig in config.fieldMappings) {
      final dynamoValue = itemData[fieldConfig.dynamoFieldName];
      final convertedValue = _convertFieldValue(dynamoValue, fieldConfig);

      if (convertedValue != null || fieldConfig.defaultValue != null) {
        mappedData[fieldConfig.shepherdFieldName] =
            convertedValue ?? fieldConfig.defaultValue;
      } else if (fieldConfig.isRequired) {
        print(
            '⚠️  Campo obrigatório "${fieldConfig.dynamoFieldName}" não encontrado em $resourceName');
        return null;
      }
    }

    // Inferir domínio se não foi mapeado
    if (!mappedData.containsKey('domainName') ||
        mappedData['domainName'] == null) {
      mappedData['domainName'] =
          _inferDomainFromName(mappedData['name']?.toString() ?? resourceName);
    }

    // Inferir domínio se não foi mapeado
    if (!mappedData.containsKey('domain') || mappedData['domain'] == null) {
      mappedData['domain'] =
          _inferDomainFromName(mappedData['name']?.toString() ?? resourceName);
    }

    // Criar entidade com valores padrão para campos não mapeados
    return EnhancedFeatureToggleEntity(
      id: null, // Será gerado pelo database
      name: _getStringValue(mappedData, 'name') ?? resourceName,
      description: _getStringValue(mappedData, 'description') ?? '',
      enabled: _getBoolValue(mappedData, 'enabled') ?? true,
      domain: _getStringValue(mappedData, 'domain') ?? 'unknown',
      activity: _getStringValue(mappedData, 'activity'),
      prototype: _getStringValue(mappedData, 'prototype'),
      team: _getStringValue(mappedData, 'team'),
      ignoreDocs: _getStringArray(mappedData, 'ignoreDocs'),
      ignoreBundleNames: _getStringArray(mappedData, 'ignoreBundleNames'),
      blockBundleNames: _getStringArray(mappedData, 'blockBundleNames'),
      minVersion: _getStringValue(mappedData, 'minVersion'),
      maxVersion: _getStringValue(mappedData, 'maxVersion'),
      createdAt: _getDateTimeValue(mappedData, 'createdAt'),
      updatedAt: _getDateTimeValue(mappedData, 'updatedAt'),
    );
  } catch (e) {
    print('⚠️  Erro ao converter $resourceName: $e');
    return null;
  }
}

dynamic _convertFieldValue(
    dynamic dynamoValue, FeatureToggleFieldConfig fieldConfig) {
  if (dynamoValue == null) return null;

  // Extrair valor do formato DynamoDB
  final actualValue = _extractDynamoValue(dynamoValue);
  if (actualValue == null) return null;

  // Converter baseado no tipo configurado
  switch (fieldConfig.fieldType) {
    case FeatureToggleFieldType.string:
      return actualValue.toString();

    case FeatureToggleFieldType.number:
      if (actualValue is num) return actualValue.toInt();
      return int.tryParse(actualValue.toString()) ?? 0;

    case FeatureToggleFieldType.boolean:
      if (actualValue is bool) return actualValue;
      if (actualValue is String) {
        return actualValue.toLowerCase() == 'true' || actualValue == '1';
      }
      return actualValue == 1 || actualValue == true;

    case FeatureToggleFieldType.stringArray:
      if (actualValue is List) {
        return actualValue
            .map((e) => _extractDynamoValue(e)?.toString() ?? '')
            .join(',');
      }
      return actualValue.toString();

    case FeatureToggleFieldType.numberArray:
      if (actualValue is List) {
        final numbers = actualValue
            .map((e) => int.tryParse(_extractDynamoValue(e)?.toString() ?? ''))
            .where((e) => e != null)
            .join(',');
        return numbers;
      }
      return actualValue.toString();
  }
}

dynamic _extractDynamoValue(dynamic dynamoValue) {
  if (dynamoValue is! Map) return dynamoValue;

  final valueMap = dynamoValue as Map<String, dynamic>;

  // Formato DynamoDB: {"S": "valor"}, {"N": "123"}, {"BOOL": true}, etc.
  if (valueMap.containsKey('S')) return valueMap['S'];
  if (valueMap.containsKey('N')) return valueMap['N'];
  if (valueMap.containsKey('BOOL')) return valueMap['BOOL'];
  if (valueMap.containsKey('SS')) return valueMap['SS']; // String Set
  if (valueMap.containsKey('NS')) return valueMap['NS']; // Number Set
  if (valueMap.containsKey('L')) return valueMap['L']; // List

  return dynamoValue;
}

String _inferDomainFromName(String name) {
  final lowerName = name.toLowerCase();

  // Regras de inferência baseadas em padrões comuns
  if (lowerName.contains('auth') ||
      lowerName.contains('login') ||
      lowerName.contains('user')) {
    return 'authentication';
  }
  if (lowerName.contains('pay') ||
      lowerName.contains('billing') ||
      lowerName.contains('subscription')) {
    return 'billing';
  }
  if (lowerName.contains('notification') ||
      lowerName.contains('email') ||
      lowerName.contains('sms')) {
    return 'notification';
  }
  if (lowerName.contains('analytics') ||
      lowerName.contains('tracking') ||
      lowerName.contains('metric')) {
    return 'analytics';
  }
  if (lowerName.contains('ui') ||
      lowerName.contains('frontend') ||
      lowerName.contains('display')) {
    return 'ui';
  }
  if (lowerName.contains('api') ||
      lowerName.contains('backend') ||
      lowerName.contains('service')) {
    return 'api';
  }

  return 'general';
}

String? _getStringValue(Map<String, dynamic> data, String key) {
  final value = data[key];
  return value?.toString();
}

bool? _getBoolValue(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return null;
}

List<String> _getStringArray(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) return [];

  if (value is String) {
    if (value.isEmpty) return [];
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }

  return [];
}

DateTime? _getDateTimeValue(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) return null;

  if (value is DateTime) return value;

  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      // Se não conseguir fazer parse, retorna null
      return null;
    }
  }

  return null;
}
