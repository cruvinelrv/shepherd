import 'dart:io';
import 'package:shepherd/src/i18n/i18n.dart';
import 'package:shepherd/src/domains/data/datasources/local/enhanced_feature_toggle_database.dart';
import 'package:shepherd/src/domains/domain/entities/enhanced_feature_toggle_entity.dart';

/// Comando para exportar feature toggles do Shepherd de volta para formato Terraform
Future<void> runExportToTerraformCommand() async {
  print(t('exp.title'));
  print('=' * 50);

  // Carregar toggles do database
  final database = EnhancedFeatureToggleDatabase(Directory.current.path);
  final toggles = await database.getAllFeatureToggles();

  if (toggles.isEmpty) {
    print(t('exp.none'));
    print(t('exp.import_first'));
    return;
  }

  print(t('exp.found', {'n': toggles.length}));

  // Request output information
  stdout.write(t('exp.table'));
  final tableName = stdin.readLineSync()?.trim() ?? 'feature-toggles';

  stdout.write(t('exp.out_path'));
  final outputPath = stdin.readLineSync()?.trim();

  if (outputPath == null || outputPath.isEmpty) {
    print(t('exp.path_required'));
    return;
  }

  try {
    // Generate Terraform content
    final terraformContent = _generateTerraformContent(toggles, tableName);

    // Show preview
    print(t('exp.preview'));
    print('-' * 50);
    final lines = terraformContent.split('\n');
    for (int i = 0; i < 15 && i < lines.length; i++) {
      print(lines[i]);
    }
    if (lines.length > 15) {
      print(t('exp.more_lines', {'n': lines.length - 15}));
    }
    print('-' * 50);

    // Confirm generation
    stdout.write(t('exp.ask_generate'));
    final confirm = stdin.readLineSync()?.trim().toLowerCase();

    if (!const {'s', 'sim', 'si', 's\u00ed', 'y', 'yes'}.contains(confirm)) {
      print(t('exp.cancelled'));
      return;
    }

    // Save file
    final outputFile = File(outputPath);
    await outputFile.writeAsString(terraformContent);

    print(t('exp.done'));
    print(t('exp.file', {'path': outputPath}));
    print(t('exp.resources', {'n': toggles.length}));
    print(t('exp.table_line', {'name': tableName}));
    print(t('exp.use'));
  } catch (e) {
    print(t('exp.failed', {'error': e}));
  }
}

String _generateTerraformContent(
    List<EnhancedFeatureToggleEntity> toggles, String tableName) {
  final buffer = StringBuffer();

  // Header do arquivo
  buffer.writeln('# Feature Toggles gerados pelo Shepherd');
  buffer.writeln('# Gerado em: ${DateTime.now().toIso8601String()}');
  buffer.writeln('# Total de toggles: ${toggles.length}');
  buffer.writeln('');

  // Generate DynamoDB resources for each toggle
  for (int i = 0; i < toggles.length; i++) {
    final toggle = toggles[i];
    final resourceName = _sanitizeResourceName(toggle.name);

    buffer.writeln(
        'resource "aws_dynamodb_table_item" "$tableName-$resourceName" {');
    buffer.writeln('  table_name = aws_dynamodb_table.$tableName.name');
    buffer.writeln('  hash_key   = aws_dynamodb_table.$tableName.hash_key');
    buffer.writeln('');
    buffer.writeln('  item = <<JSON');
    buffer.writeln('{');

    // Campos obrigatórios
    buffer.writeln('  "name": {"S": "${_escapeJson(toggle.name)}"},');
    buffer.writeln('  "status": {"N": "${toggle.enabled ? 1 : 0}"},');
    buffer.writeln(
        '  "description": {"S": "${_escapeJson(toggle.description)}"},');

    // Campos opcionais
    if (toggle.activity != null && toggle.activity!.isNotEmpty) {
      buffer
          .writeln('  "activity": {"S": "${_escapeJson(toggle.activity!)}"},');
    }

    if (toggle.team != null && toggle.team!.isNotEmpty) {
      buffer.writeln('  "team": {"S": "${_escapeJson(toggle.team!)}"},');
    }

    if (toggle.prototype != null && toggle.prototype!.isNotEmpty) {
      buffer.writeln(
          '  "prototype": {"S": "${_escapeJson(toggle.prototype!)}"},');
    }

    if (toggle.minVersion != null && toggle.minVersion!.isNotEmpty) {
      buffer.writeln(
          '  "minVersion": {"S": "${_escapeJson(toggle.minVersion!)}"},');
    }

    if (toggle.maxVersion != null && toggle.maxVersion!.isNotEmpty) {
      buffer.writeln(
          '  "maxVersion": {"S": "${_escapeJson(toggle.maxVersion!)}"},');
    }

    // Arrays
    if (toggle.ignoreDocs.isNotEmpty) {
      final docsArray =
          toggle.ignoreDocs.map((doc) => '"${_escapeJson(doc)}"').join(', ');
      buffer.writeln('  "ignoreDocs": {"SS": [$docsArray]},');
    } else {
      buffer.writeln('  "ignoreDocs": {"SS": [""]},');
    }

    if (toggle.ignoreBundleNames.isNotEmpty) {
      final bundlesArray = toggle.ignoreBundleNames
          .map((bundle) => '"${_escapeJson(bundle)}"')
          .join(', ');
      buffer.writeln('  "ignoreBundleNames": {"SS": [$bundlesArray]},');
    } else {
      buffer.writeln('  "ignoreBundleNames": {"SS": [""]},');
    }

    if (toggle.blockBundleNames.isNotEmpty) {
      final blockArray = toggle.blockBundleNames
          .map((block) => '"${_escapeJson(block)}"')
          .join(', ');
      buffer.writeln('  "blockBundleNames": {"SS": [$blockArray]},');
    } else {
      buffer.writeln('  "blockBundleNames": {"SS": [""]},');
    }

    buffer.writeln('}');
    buffer.writeln('JSON');
    buffer.writeln('}');

    if (i < toggles.length - 1) {
      buffer.writeln('');
    }
  }

  return buffer.toString();
}

String _sanitizeResourceName(String name) {
  // Sanitize name for use as Terraform resource name
  return name
      .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

String _escapeJson(String value) {
  // Escape special characters for JSON
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}
