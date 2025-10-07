import 'package:yaml_writer/yaml_writer.dart';

/// Configuração de campos para importação de feature toggles
///
/// Este arquivo permite que diferentes empresas configurem
/// quais campos existem em seus arquivos DynamoDB/Terraform
/// e como eles devem ser mapeados para o Shepherd.
class FeatureToggleFieldConfig {
  final String dynamoFieldName;
  final String shepherdFieldName;
  final FeatureToggleFieldType fieldType;
  final bool isRequired;
  final dynamic defaultValue;
  final String? description;

  const FeatureToggleFieldConfig({
    required this.dynamoFieldName,
    required this.shepherdFieldName,
    required this.fieldType,
    this.isRequired = false,
    this.defaultValue,
    this.description,
  });

  Map<String, dynamic> toYaml() => {
        'dynamoFieldName': dynamoFieldName,
        'shepherdFieldName': shepherdFieldName,
        'fieldType': fieldType.name,
        'isRequired': isRequired,
        if (defaultValue != null) 'defaultValue': defaultValue,
        if (description != null) 'description': description,
      };

  factory FeatureToggleFieldConfig.fromYaml(Map<String, dynamic> yaml) =>
      FeatureToggleFieldConfig(
        dynamoFieldName: yaml['dynamoFieldName'],
        shepherdFieldName: yaml['shepherdFieldName'],
        fieldType: FeatureToggleFieldType.values
            .firstWhere((e) => e.name == yaml['fieldType']),
        isRequired: yaml['isRequired'] ?? false,
        defaultValue: yaml['defaultValue'],
        description: yaml['description'],
      );
}

enum FeatureToggleFieldType {
  string, // "S" no DynamoDB
  number, // "N" no DynamoDB
  boolean, // "BOOL" no DynamoDB ou conversão de "N"
  stringArray, // "SS" no DynamoDB
  numberArray, // "NS" no DynamoDB
}

/// Configuração completa de importação para uma empresa
class ImportConfiguration {
  final String configName;
  final String version;
  final String description;
  final List<FeatureToggleFieldConfig> fieldMappings;
  final Map<String, String> domainInferenceRules;
  final Map<String, dynamic> customSettings;

  const ImportConfiguration({
    required this.configName,
    required this.version,
    required this.description,
    required this.fieldMappings,
    this.domainInferenceRules = const {},
    this.customSettings = const {},
  });

  Map<String, dynamic> toYaml() => {
        'configName': configName,
        'version': version,
        'description': description,
        'fieldMappings': fieldMappings.map((f) => f.toYaml()).toList(),
        'domainInferenceRules': domainInferenceRules,
        'customSettings': customSettings,
      };

  factory ImportConfiguration.fromYaml(Map<String, dynamic> yaml) =>
      ImportConfiguration(
        configName: yaml['configName'],
        version: yaml['version'],
        description: yaml['description'],
        fieldMappings: (yaml['fieldMappings'] as List)
            .map((f) =>
                FeatureToggleFieldConfig.fromYaml(Map<String, dynamic>.from(f)))
            .toList(),
        domainInferenceRules:
            Map<String, String>.from(yaml['domainInferenceRules'] ?? {}),
        customSettings: Map<String, dynamic>.from(yaml['customSettings'] ?? {}),
      );

  String toYamlString() {
    final yamlWriter = YamlWriter();
    return yamlWriter.write(toYaml());
  }
}

/// Configurações pré-definidas para diferentes tipos de empresas
class PredefinedConfigurations {
  /// Configuração padrão com campos avançados (baseada em estrutura comum de empresas)
  static const ImportConfiguration defaultAdvanced = ImportConfiguration(
    configName: 'Advanced Enterprise',
    version: '1.0.0',
    description: 'Configuração avançada com campos empresariais comuns',
    fieldMappings: [
      FeatureToggleFieldConfig(
        dynamoFieldName: 'name',
        shepherdFieldName: 'name',
        fieldType: FeatureToggleFieldType.string,
        isRequired: true,
        description: 'Nome único do feature toggle',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'status',
        shepherdFieldName: 'enabled',
        fieldType: FeatureToggleFieldType.number,
        isRequired: true,
        defaultValue: 0,
        description: 'Status: 1 = habilitado, 0 = desabilitado',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'description',
        shepherdFieldName: 'description',
        fieldType: FeatureToggleFieldType.string,
        isRequired: false,
        defaultValue: '',
        description: 'Descrição funcional do toggle',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'activity',
        shepherdFieldName: 'activity',
        fieldType: FeatureToggleFieldType.string,
        isRequired: false,
        description: 'Número da atividade/task relacionada',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'team',
        shepherdFieldName: 'team',
        fieldType: FeatureToggleFieldType.string,
        isRequired: false,
        description: 'Equipe responsável do feature toggle',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'prototype',
        shepherdFieldName: 'prototype',
        fieldType: FeatureToggleFieldType.string,
        isRequired: false,
        description: 'URL do protótipo Figma',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'ignoreDocs',
        shepherdFieldName: 'ignoreDocs',
        fieldType: FeatureToggleFieldType.stringArray,
        isRequired: false,
        description: 'Lista de documentos/CPFs a ignorar',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'ignoreBundleNames',
        shepherdFieldName: 'ignoreBundleNames',
        fieldType: FeatureToggleFieldType.stringArray,
        isRequired: false,
        description: 'Lista de bundles a ignorar',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'blockBundleNames',
        shepherdFieldName: 'blockBundleNames',
        fieldType: FeatureToggleFieldType.stringArray,
        isRequired: false,
        description: 'Lista de bundles a bloquear',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'minVersion',
        shepherdFieldName: 'minVersion',
        fieldType: FeatureToggleFieldType.string,
        isRequired: false,
        description: 'Versão mínima suportada',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'maxVersion',
        shepherdFieldName: 'maxVersion',
        fieldType: FeatureToggleFieldType.string,
        isRequired: false,
        description: 'Versão máxima suportada',
      ),
    ],
    domainInferenceRules: {
      'authentication': r'auth|login|user|signup',
      'billing': r'billing|payment|subscription|charge',
      'notification': r'notification|email|sms|push',
      'analytics': r'analytics|tracking|metrics|events',
      'ui': r'ui|frontend|display|interface',
      'api': r'api|backend|service|endpoint',
    },
  );

  /// Configuração simples para empresas com estrutura básica
  static const ImportConfiguration simpleConfiguration = ImportConfiguration(
    configName: 'Basic Enterprise',
    version: '1.0.0',
    description: 'Configuração básica com campos essenciais',
    fieldMappings: [
      FeatureToggleFieldConfig(
        dynamoFieldName: 'name',
        shepherdFieldName: 'name',
        fieldType: FeatureToggleFieldType.string,
        isRequired: true,
        description: 'Nome do feature toggle',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'enabled',
        shepherdFieldName: 'enabled',
        fieldType: FeatureToggleFieldType.boolean,
        isRequired: true,
        defaultValue: false,
        description: 'Status habilitado/desabilitado',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'description',
        shepherdFieldName: 'description',
        fieldType: FeatureToggleFieldType.string,
        isRequired: false,
        defaultValue: '',
        description: 'Descrição do toggle',
      ),
      FeatureToggleFieldConfig(
        dynamoFieldName: 'environment',
        shepherdFieldName: 'team',
        fieldType: FeatureToggleFieldType.string,
        isRequired: false,
        description: 'Ambiente ou equipe',
      ),
    ],
    domainInferenceRules: {
      'user': r'user|profile|account',
      'payment': r'payment|billing|checkout',
      'product': r'product|catalog|inventory',
      'notification': r'notification|email|sms',
    },
  );

  /// Lista de todas as configurações disponíveis
  static List<ImportConfiguration> get allConfigurations => [
        defaultAdvanced,
        simpleConfiguration,
      ];

  /// Buscar configuração por nome
  static ImportConfiguration? getByName(String name) {
    try {
      return allConfigurations.firstWhere(
          (config) => config.configName.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}
