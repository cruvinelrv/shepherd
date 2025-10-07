import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/domains/presentation/commands/feature_toggles/import_field_configuration.dart';

/// Command to configure feature toggle import fields
Future<void> runConfigureImportFieldsCommand() async {
  print('🔧 Import Field Configuration');
  print('=' * 50);
  print('Configure how your DynamoDB/Terraform fields');
  print('should be mapped to Shepherd.\n');

  while (true) {
    print('Options:');
    print('1. Use predefined configuration');
    print('2. Create custom configuration');
    print('3. View existing configurations');
    print('4. Export current configuration');
    print('5. Import configuration from file');
    print('6. Go back');

    stdout.write('\nChoose an option (1-6): ');
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
        print('❌ Invalid option. Try again.');
    }

    print('\n${'=' * 50}');
  }
}

Future<void> _usePredefinedConfiguration() async {
  print('\n📋 Predefined Configurations:');

  final configs = PredefinedConfigurations.allConfigurations;
  for (int i = 0; i < configs.length; i++) {
    final config = configs[i];
    print('${i + 1}. ${config.configName} (v${config.version})');
    print('   ${config.description}');
    print('   📊 ${config.fieldMappings.length} mapped fields');
  }

  stdout.write('\nChoose a configuration (1-${configs.length}): ');
  final choice = stdin.readLineSync()?.trim();

  if (choice == null || choice.isEmpty) {
    print('❌ Invalid option.');
    return;
  }

  final index = int.tryParse(choice);
  if (index == null || index < 1 || index > configs.length) {
    print('❌ Invalid option.');
    return;
  }

  final selectedConfig = configs[index - 1];
  await _saveConfiguration(selectedConfig);

  print(
      '\n✅ Configuration "${selectedConfig.configName}" applied successfully!');
  print('📁 File saved to: .shepherd/import_config.yaml');
}

Future<void> _createCustomConfiguration() async {
  print('\n🛠️  Creating Custom Configuration');

  stdout.write('Configuration name: ');
  final name = stdin.readLineSync()?.trim() ?? '';

  stdout.write('Version (e.g: 1.0.0): ');
  final version = stdin.readLineSync()?.trim() ?? '1.0.0';

  stdout.write('Description: ');
  final description = stdin.readLineSync()?.trim() ?? '';

  final fieldMappings = <FeatureToggleFieldConfig>[];

  print('\n📋 Now let\'s configure the fields:');
  print('(Type "done" when finished adding fields)');

  while (true) {
    print('\n--- New Field ---');

    stdout.write('DynamoDB field name (e.g: name, status): ');
    final dynamoField = stdin.readLineSync()?.trim() ?? '';

    if (dynamoField.toLowerCase() == 'done') break;
    if (dynamoField.isEmpty) continue;

    stdout.write('Shepherd field name (e.g: name, enabled): ');
    final shepherdField = stdin.readLineSync()?.trim() ?? dynamoField;

    print('Field type:');
    print('1. String (text)');
    print('2. Number');
    print('3. Boolean (true/false)');
    print('4. String Array (list of texts)');
    print('5. Number Array (list of numbers)');

    stdout.write('Choose type (1-5): ');
    final typeChoice = stdin.readLineSync()?.trim() ?? '1';

    final fieldType = switch (typeChoice) {
      '2' => FeatureToggleFieldType.number,
      '3' => FeatureToggleFieldType.boolean,
      '4' => FeatureToggleFieldType.stringArray,
      '5' => FeatureToggleFieldType.numberArray,
      _ => FeatureToggleFieldType.string,
    };

    stdout.write('Is required? (y/n): ');
    final isRequired = stdin.readLineSync()?.trim().toLowerCase() == 'y';

    stdout.write('Default value (leave empty if none): ');
    final defaultValue = stdin.readLineSync()?.trim();

    stdout.write('Field description: ');
    final fieldDescription = stdin.readLineSync()?.trim();

    fieldMappings.add(FeatureToggleFieldConfig(
      dynamoFieldName: dynamoField,
      shepherdFieldName: shepherdField,
      fieldType: fieldType,
      isRequired: isRequired,
      defaultValue: defaultValue?.isNotEmpty == true ? defaultValue : null,
      description:
          fieldDescription?.isNotEmpty == true ? fieldDescription : null,
    ));

    print('✅ Field "$dynamoField" added!');
  }

  if (fieldMappings.isEmpty) {
    print('❌ No fields were configured.');
    return;
  }

  final config = ImportConfiguration(
    configName: name,
    version: version,
    description: description,
    fieldMappings: fieldMappings,
  );

  await _saveConfiguration(config);

  print('\n✅ Custom configuration created successfully!');
  print('📊 ${fieldMappings.length} fields configured');
  print('📁 File saved to: .shepherd/import_config.yaml');
}

Future<void> _viewExistingConfigurations() async {
  print('\n👀 Existing Configurations:');

  // Show predefined configurations
  print('\n📋 Predefined:');
  for (final config in PredefinedConfigurations.allConfigurations) {
    print('\n🏷️  ${config.configName} (v${config.version})');
    print('   📝 ${config.description}');
    print('   📊 ${config.fieldMappings.length} fields:');

    for (final field in config.fieldMappings.take(5)) {
      final required = field.isRequired ? ' (required)' : '';
      print(
          '     • ${field.dynamoFieldName} → ${field.shepherdFieldName}$required');
    }

    if (config.fieldMappings.length > 5) {
      print('     ... and ${config.fieldMappings.length - 5} more fields');
    }
  }

  // Show current configuration if exists
  final currentConfig = await _loadCurrentConfiguration();
  if (currentConfig != null) {
    print('\n📁 Current Configuration:');
    print('🏷️  ${currentConfig.configName} (v${currentConfig.version})');
    print('   📝 ${currentConfig.description}');
    print('   📊 ${currentConfig.fieldMappings.length} configured fields');
  }
}

Future<void> _exportConfiguration() async {
  final currentConfig = await _loadCurrentConfiguration();

  if (currentConfig == null) {
    print('❌ No active configuration found.');
    return;
  }

  stdout.write('Path to save configuration file: ');
  final filePath = stdin.readLineSync()?.trim();

  if (filePath == null || filePath.isEmpty) {
    print('❌ Invalid path.');
    return;
  }

  try {
    final file = File(filePath);
    final yamlStr = currentConfig.toYamlString();
    await file.writeAsString(yamlStr);

    print('✅ Configuration exported to: $filePath');
  } catch (e) {
    print('❌ Error exporting configuration: $e');
  }
}

Future<void> _importConfiguration() async {
  stdout.write('Configuration file path: ');
  final filePath = stdin.readLineSync()?.trim();

  if (filePath == null || filePath.isEmpty) {
    print('❌ Invalid path.');
    return;
  }

  final file = File(filePath);
  if (!await file.exists()) {
    print('❌ File not found: $filePath');
    return;
  }

  try {
    final content = await file.readAsString();
    final yamlData = loadYaml(content);
    final config =
        ImportConfiguration.fromYaml(Map<String, dynamic>.from(yamlData));

    await _saveConfiguration(config);

    print('✅ Configuration imported successfully!');
    print('🏷️  ${config.configName} (v${config.version})');
    print('📊 ${config.fieldMappings.length} configured fields');
  } catch (e) {
    print('❌ Error importing configuration: $e');
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
    print('⚠️  Error loading configuration: $e');
    return null;
  }
}
