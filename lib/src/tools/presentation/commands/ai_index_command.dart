import 'dart:io';
import 'package:args/args.dart';
import '../../domain/services/ai_rag_service.dart';
import '../../../utils/ai_i18n_helper.dart';
import '../../../utils/ansi_colors.dart';

/// Executa a indexação vetorial local do workspace ou exibe o status do banco vetorial.
Future<void> runAiIndexCommand(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Force complete re-indexing of all files (EN).',
    )
    ..addFlag(
      'forcar',
      negatable: false,
      help: 'Força a re-indexação completa de todos os arquivos (PT).',
    )
    ..addFlag(
      'forzar',
      negatable: false,
      help: 'Fuerza la reindexación completa de todos los archivos (ES).',
    )
    ..addFlag(
      'status',
      abbr: 's',
      negatable: false,
      help: 'Show vector database status and metrics (EN / PT).',
    )
    ..addFlag(
      'estado',
      negatable: false,
      help: 'Muestra el estado del banco vectorial (ES).',
    )
    ..addFlag(
      'clear',
      negatable: false,
      help: 'Clear the local vector database (EN).',
    )
    ..addFlag(
      'limpar',
      negatable: false,
      help: 'Limpa a base vetorial local (PT).',
    )
    ..addFlag(
      'limpiar',
      negatable: false,
      help: 'Limpia la base vectorial local (ES).',
    )
    ..addOption(
      'project',
      abbr: 'p',
      help: 'Index only a specific project (EN).',
    )
    ..addOption(
      'projeto',
      help: 'Indexa apenas um projeto específico (PT / ES).',
    );

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    stderr.writeln('❌ ${e.toString()}');
    return;
  }

  final isForce = argResults['force'] == true ||
      argResults['forcar'] == true ||
      argResults['forzar'] == true;

  final isStatus = argResults['status'] == true || argResults['estado'] == true;

  final isClear = argResults['clear'] == true ||
      argResults['limpar'] == true ||
      argResults['limpiar'] == true;

  final targetProject = (argResults['project'] ?? argResults['projeto']) as String?;

  final ragService = AiRagService();
  final locale = AiI18nHelper.systemLocale;

  // 1. Limpeza
  if (isClear) {
    if (locale == 'es') {
      print('${AnsiColors.yellow}🗑️  Limpiando base vectorial local...${AnsiColors.reset}');
    } else if (locale == 'pt') {
      print('${AnsiColors.yellow}🗑️  Limpando base vetorial local...${AnsiColors.reset}');
    } else {
      print('${AnsiColors.yellow}🗑️  Clearing local vector database...${AnsiColors.reset}');
    }

    await ragService.clearIndex();

    if (locale == 'es') {
      print('${AnsiColors.green}✅ Base vectorial eliminada con éxito.${AnsiColors.reset}');
    } else if (locale == 'pt') {
      print('${AnsiColors.green}✅ Base vetorial limpa com sucesso.${AnsiColors.reset}');
    } else {
      print('${AnsiColors.green}✅ Local vector database cleared successfully.${AnsiColors.reset}');
    }
    return;
  }

  // 2. Status
  if (isStatus) {
    final stats = await ragService.getStats();
    print('\n${AnsiColors.bold}📊 Shepherd AI — Local Vector Store (RAG)${AnsiColors.reset}');
    print('────────────────────────────────────────────────────────');
    print('${AnsiColors.gray}Localização no disco:${AnsiColors.reset} ${AnsiColors.brightCyan}${stats.dbPath}${AnsiColors.reset}');
    print('${AnsiColors.gray}Total de Chunks:${AnsiColors.reset}      ${AnsiColors.brightGreen}${stats.totalChunks}${AnsiColors.reset}');
    print('${AnsiColors.gray}Arquivos Indexados:${AnsiColors.reset}   ${stats.totalFiles}');
    print('${AnsiColors.gray}Projetos no Índice:${AnsiColors.reset}   ${stats.totalProjects}');
    print('${AnsiColors.gray}Tokens Estimados:${AnsiColors.reset}     ${stats.totalTokens}');
    if (stats.lastUpdated != null) {
      print('${AnsiColors.gray}Última Atualização:${AnsiColors.reset}   ${stats.lastUpdated!.toLocal()}');
    }
    print('────────────────────────────────────────────────────────');
    print('${AnsiColors.gray}🔒 100% Local, Privado e Offline. Nenhum dado é enviado à nuvem.${AnsiColors.reset}\n');
    return;
  }

  // 3. Indexação
  if (locale == 'es') {
    print('\n${AnsiColors.bold}⚡ Iniciando indexación vectorial del workspace...${AnsiColors.reset}');
  } else if (locale == 'pt') {
    print('\n${AnsiColors.bold}⚡ Iniciando indexação vetorial do workspace...${AnsiColors.reset}');
  } else {
    print('\n${AnsiColors.bold}⚡ Starting workspace vector indexing...${AnsiColors.reset}');
  }

  final result = await ragService.indexWorkspace(
    force: isForce,
    specificProject: targetProject,
    onProgress: (msg) => print('${AnsiColors.gray}$msg${AnsiColors.reset}'),
  );

  print('\n${AnsiColors.green}✅ Indexação concluída em ${result.durationMs}ms!${AnsiColors.reset}');
  print('────────────────────────────────────────────────────────');
  print('📁 Arquivos analisados:     ${result.totalDiscoveredFiles}');
  print('✨ Arquivos indexados:      ${result.indexedFiles}');
  print('⏩ Arquivos inalterados:    ${result.skippedFiles}');
  print('🧩 Novos Chunks gerados:    ${result.totalChunks}');
  print('💾 Banco local salvo em:    ${AnsiColors.brightCyan}.shepherd/vectors/embeddings.db${AnsiColors.reset}');
  print('────────────────────────────────────────────────────────');
  print('${AnsiColors.brightGreen}Pronto! Agora qualquer pergunta em `shepherd ai` utilizará RAG local instantâneo.${AnsiColors.reset}\n');
}
