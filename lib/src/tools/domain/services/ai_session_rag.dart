import 'dart:io';

import 'package:path/path.dart' as p;

import '../../data/models/ai_vector_chunk_model.dart';
import '../entities/ai_vector_chunk_entity.dart';
import 'ai_config_service.dart' show AiConfigModel;
import 'ai_context_budget_service.dart';
import 'ai_embedding_service.dart';
import 'ai_jsonl_protocol.dart';
import 'ai_rag_service.dart';
import 'ai_settings_resolver.dart' show filterManifestProjects;
import 'ai_workspace_scanner_service.dart' show AiWorkspaceScannerService;
import 'workspace_manifest_service.dart';

class AiSessionRagResult {
  final String context;
  final int chunks;
  final List<String> files;
  const AiSessionRagResult(this.context, this.chunks, this.files);
  static const empty = AiSessionRagResult('', 0, []);
}

/// RAG for a conversation over a workspace whose projects are registered in
/// `.shepherd/workspace.yaml` (the host, e.g. Shepherd Studio, keeps that file
/// in step with the project folders). Vectors live in one store at
/// `<workspace>/.shepherd/vectors`, tagged by project, so a selection of
/// projects can be searched. Without registered projects the workspace is
/// indexed as one project.
///
/// All vectors must come from the same embedding backend. The backend is
/// probed once; if it later falls back (e.g. Ollama times out) the affected
/// chunk is skipped instead of stored, and an index built by a different
/// backend is dropped and rebuilt.
class AiSessionRag {
  final String workspaceRoot;

  /// Selected projects (id, name or folder); empty means every project.
  List<String> projects;
  final int topK;
  final AiEmbeddingService _inner;
  late final _GuardedEmbedding _guard = _GuardedEmbedding(_inner);
  late final AiRagService _service = AiRagService(
    basePath: workspaceRoot,
    embeddingService: _guard,
  );

  AiSessionRag({
    required this.workspaceRoot,
    this.projects = const [],
    this.topK = 4,
    AiEmbeddingService? embedding,
  }) : _inner = embedding ?? AiEmbeddingService();

  File get _signatureFile =>
      File(p.join(workspaceRoot, '.shepherd', 'vectors', 'embedding_signature'));

  /// Which chunks the selected projects allow. With nothing selected, all. A
  /// selection that matches nothing allows nothing: it must never widen to the
  /// whole workspace.
  bool Function(AiVectorChunkEntity) _selectionFilter() {
    if (projects.isEmpty) return (_) => true;
    // The company Wiki is knowledge for every question, not part of a project.
    bool isWiki(AiVectorChunkEntity c) =>
        c.projectName == AiWorkspaceScannerService.wikiProjectName;

    final manifest = WorkspaceManifest.tryLoad(Directory(workspaceRoot));
    if (manifest != null && manifest.projects.isNotEmpty) {
      // Registered projects: chunks are tagged with the project name.
      final names = filterManifestProjects(manifest, projects).projects.map((e) => e.name).toSet();
      return (c) => isWiki(c) || names.contains(c.projectName);
    }

    // No registered projects: the whole workspace is one project and paths are
    // relative to its root, so the selected folder is the first path segment.
    String top(String path) => path.replaceAll('\\', '/').replaceFirst(RegExp(r'^\./'), '').split('/').first;
    final folders = projects.map(top).toSet();
    return (c) => isWiki(c) || folders.contains(top(c.filePath));
  }

  Directory get _wikiDir =>
      Directory(p.join(workspaceRoot, '.shepherd', 'wiki'));

  bool get _hasWiki =>
      _wikiDir.existsSync() &&
      _wikiDir.listSync().any((e) => e is File && e.path.endsWith('.md'));

  /// Brings the Wiki pages up to date; if the folder is gone (the account
  /// signed out), forgets the pages that were indexed from it.
  Future<int> _indexWiki() async {
    const name = AiWorkspaceScannerService.wikiProjectName;
    if (!_hasWiki) {
      if (_service.isIndexed) await _service.database.clearProject(name);
      return 0;
    }
    return (await _service.indexWorkspace(specificProject: name)).indexedFiles;
  }

  /// Registered projects in scope. Empty when the workspace has none.
  List<WorkspaceProject> _scope() {
    var manifest = WorkspaceManifest.tryLoad(Directory(workspaceRoot));
    if (manifest == null || manifest.projects.isEmpty) return [];
    if (projects.isNotEmpty) manifest = filterManifestProjects(manifest, projects);
    return manifest.projects;
  }

  /// Probes the embedding backend, resets the index if the backend changed,
  /// then brings every project up to date (incremental).
  Stream<AiEvent> prepare() async* {
    final probe = await _inner.getEmbedding('shepherd');
    final source = _inner.lastSource;
    _guard.expected = source;
    final signature = '$source:${probe.length}';

    final file = _signatureFile;
    final previous = file.existsSync() ? file.readAsStringSync().trim() : null;
    if (previous != null && previous != signature) await _service.clearIndex();
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(signature);

    final scope = _scope();
    if (scope.isEmpty) {
      yield AiEvent.indexProgress('(workspace)', 'start');
      final n = (await _service.indexWorkspace()).indexedFiles;
      yield AiEvent.indexProgress('(workspace)', 'done', indexedFiles: n);
    }
    for (final proj in scope) {
      yield AiEvent.indexProgress(proj.name, 'start');
      final n = (await _service.indexWorkspace(specificProject: proj.name)).indexedFiles;
      yield AiEvent.indexProgress(proj.name, 'done', indexedFiles: n);
    }
    if (scope.isNotEmpty) {
      const wiki = AiWorkspaceScannerService.wikiProjectName;
      if (_hasWiki) yield AiEvent.indexProgress(wiki, 'start');
      final n = await _indexWiki();
      if (n > 0 || _hasWiki) {
        yield AiEvent.indexProgress(wiki, 'done', indexedFiles: n);
      }
    }
    yield AiEvent.indexDone(source: source, projects: scope.length);
  }

  /// Silently brings the projects now in scope up to date (incremental).
  Future<void> indexScope() async {
    if (_guard.expected == null) return;
    final scope = _scope();
    if (scope.isEmpty) {
      await _service.indexWorkspace();
      return;
    }
    for (final proj in scope) {
      await _service.indexWorkspace(specificProject: proj.name);
    }
    await _indexWiki();
  }

  /// Re-indexes the project that owns [folder] (e.g. after the AI wrote a
  /// file into it).
  Future<void> reindexProject(String folder) async {
    if (_guard.expected == null) return;
    final scope = _scope();
    if (scope.isEmpty) {
      await _service.indexWorkspace();
      return;
    }
    for (final proj in scope) {
      final path = proj.path.replaceAll('\\', '/');
      if (proj.name == folder || proj.id == folder || path == folder || path.split('/').last == folder) {
        await _service.indexWorkspace(specificProject: proj.name);
      }
    }
  }

  /// The most relevant snippets for [query] within the selected projects.
  Future<AiSessionRagResult> contextFor(String query, {required bool isLocal}) async {
    if (!_service.isIndexed || _guard.expected == null) return AiSessionRagResult.empty;
    // Over-fetch, then keep only the selected projects.
    final all = await _service.retrieveRelevantChunks(query: query, topK: topK * 4);
    final inSelection = _selectionFilter();
    final matches = [
      for (final m in all)
        if (inSelection(m.chunk)) m,
    ].take(topK).toList();
    if (matches.isEmpty) return AiSessionRagResult.empty;

    return AiSessionRagResult(
      AiContextBudgetService.formatBudgetedRagContext(
        [for (final m in matches) AiRagMatchModel(chunk: m.chunk, score: m.score)],
        isLocal: isLocal,
      ),
      matches.length,
      {for (final m in matches) '${m.chunk.projectName}/${m.chunk.filePath}'}.toList(),
    );
  }
}

/// Throws when the backend that produced a vector is not the one the index
/// was built with, so the caller skips it rather than mixing vector spaces.
class _GuardedEmbedding extends AiEmbeddingService {
  final AiEmbeddingService _inner;
  String? expected;
  _GuardedEmbedding(this._inner);

  @override
  Future<List<double>> getEmbedding(String text, {AiConfigModel? config}) async {
    final v = await _inner.getEmbedding(text, config: config);
    if (expected != null && _inner.lastSource != expected) {
      throw StateError('Embedding backend changed to ${_inner.lastSource}');
    }
    return v;
  }
}
