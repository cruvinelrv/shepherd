import 'dart:io';
import 'dart:convert';
import 'package:shepherd/src/domains/data/datasources/local/enhanced_feature_toggle_database.dart';

Future<void> runImportDynamoDBCommand() async {
  stdout.write('Caminho para o arquivo Terraform (.tf): ');
  final filePath = stdin.readLineSync();

  if (filePath == null || filePath.isEmpty) {
    print('Caminho do arquivo é obrigatório.');
    return;
  }

  final file = File(filePath);
  if (!await file.exists()) {
    print('Arquivo não encontrado: $filePath');
    return;
  }

  try {
    print('Lendo arquivo Terraform...');
    final content = await file.readAsString();

    // Parse básico dos recursos DynamoDB do Terraform
    final items = _parseDynamoDBItems(content);

    if (items.isEmpty) {
      print('Nenhum item de feature toggle encontrado no arquivo.');
      return;
    }

    print('Encontrados ${items.length} feature toggles. Importando...');

    final db = EnhancedFeatureToggleDatabase(Directory.current.path);
    await db.importFromDynamoDBTerraform(items);

    // Export to YAML after import
    await exportEnhancedFeatureTogglesToYaml(db, Directory.current.path);

    print('✅ Importação concluída com sucesso!');
    print(
        'Os feature toggles foram salvos no banco e exportados para .shepherd/enhanced_feature_toggles.yaml');
  } catch (e) {
    print('❌ Erro durante a importação: $e');
  }
}

List<Map<String, dynamic>> _parseDynamoDBItems(String terraformContent) {
  final items = <Map<String, dynamic>>[];

  // Find all "aws_dynamodb_table_item" resource blocks
  final resourceRegex = RegExp(
      r'resource\s+"aws_dynamodb_table_item"\s+"[^"]+"\s*\{([^}]+item\s*=\s*<<ITEM[\s\S]*?ITEM[^}]*)\}',
      multiLine: true);

  final matches = resourceRegex.allMatches(terraformContent);

  for (final match in matches) {
    try {
      final resourceContent = match.group(1) ?? '';

      // Extrair o conteúdo JSON entre <<ITEM e ITEM
      final itemRegex = RegExp(r'<<ITEM\s*([\s\S]*?)\s*ITEM', multiLine: true);
      final itemMatch = itemRegex.firstMatch(resourceContent);

      if (itemMatch != null) {
        final jsonString = itemMatch.group(1)?.trim() ?? '';
        if (jsonString.isNotEmpty) {
          try {
            final jsonData = json.decode(jsonString);
            items.add(jsonData);
          } catch (jsonError) {
            print('Erro ao parsear JSON do item: $jsonError');
            print('JSON problemático: $jsonString');
          }
        }
      }
    } catch (e) {
      print('Erro ao processar resource: $e');
    }
  }

  return items;
}

/// Exporta enhanced feature toggles para YAML
Future<void> exportEnhancedFeatureTogglesToYaml(
    EnhancedFeatureToggleDatabase db, String projectPath) async {
  try {
    final toggles = await db.getAllFeatureToggles();

    // Group by domain
    final togglesByDomain = <String, List<Map<String, dynamic>>>{};

    for (final toggle in toggles) {
      final domain = toggle.domain;
      togglesByDomain.putIfAbsent(domain, () => []).add(toggle.toYaml());
    }

    // Create organized YAML structure (for future reference if needed)

    // Generate YAML string manually for better formatting
    final buffer = StringBuffer();
    buffer.writeln('# Enhanced Feature Toggles');
    buffer.writeln('# Exported from Shepherd at ${DateTime.now()}');
    buffer.writeln(
        '# Total: ${toggles.length} feature toggles across ${togglesByDomain.length} domains');
    buffer.writeln();

    buffer.writeln('enhanced_feature_toggles:');
    for (final domain in togglesByDomain.keys) {
      buffer.writeln('  $domain:');
      final domainToggles = togglesByDomain[domain]!;

      for (final toggle in domainToggles) {
        buffer.writeln('    - name: ${toggle['name']}');
        buffer.writeln('      enabled: ${toggle['enabled']}');
        buffer.writeln('      description: "${toggle['description']}"');

        if (toggle['activity'] != null) {
          buffer.writeln('      activity: "${toggle['activity']}"');
        }
        if (toggle['team'] != null) {
          buffer.writeln('      team: ${toggle['team']}');
        }
        if (toggle['prototype'] != null) {
          buffer.writeln('      prototype: "${toggle['prototype']}"');
        }
        if (toggle['minVersion'] != null) {
          buffer.writeln('      minVersion: "${toggle['minVersion']}"');
        }
        if (toggle['maxVersion'] != null) {
          buffer.writeln('      maxVersion: "${toggle['maxVersion']}"');
        }

        // Arrays
        if (toggle['ignoreDocs'] != null && (toggle['ignoreDocs'] as List).isNotEmpty) {
          buffer.writeln('      ignoreDocs:');
          for (final doc in toggle['ignoreDocs'] as List) {
            buffer.writeln('        - "$doc"');
          }
        }
        if (toggle['ignoreBundleNames'] != null &&
            (toggle['ignoreBundleNames'] as List).isNotEmpty) {
          buffer.writeln('      ignoreBundleNames:');
          for (final bundle in toggle['ignoreBundleNames'] as List) {
            buffer.writeln('        - "$bundle"');
          }
        }
        if (toggle['blockBundleNames'] != null && (toggle['blockBundleNames'] as List).isNotEmpty) {
          buffer.writeln('      blockBundleNames:');
          for (final bundle in toggle['blockBundleNames'] as List) {
            buffer.writeln('        - "$bundle"');
          }
        }
        buffer.writeln();
      }
    }

    buffer.writeln('metadata:');
    buffer.writeln('  total_toggles: ${toggles.length}');
    buffer.writeln('  domains: ${togglesByDomain.keys.toList()}');
    buffer.writeln('  exported_at: "${DateTime.now().toIso8601String()}"');
    buffer.writeln('  version: "1.0.0"');

    final exportDir = Directory('$projectPath/.shepherd');
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }

    final file = File('${exportDir.path}/enhanced_feature_toggles.yaml');
    await file.writeAsString(buffer.toString());

    print('📄 Enhanced feature toggles exportados para: ${file.path}');
  } catch (e) {
    print('❌ Erro ao exportar enhanced feature toggles: $e');
  }
}
