import 'dart:io';

import 'package:path/path.dart' as p;

import '../../data/models/ai_vector_chunk_model.dart';
import 'ai_config_service.dart' show AiConfigModel;
import 'ai_context_budget_service.dart';
import 'ai_embedding_service.dart';
import 'ai_jsonl_protocol.dart';
import 'ai_rag_service.dart';
import 'ai_settings_resolver.dart' show filterManifestProjects;
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
  final List<String> projects;
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
    yield AiEvent.indexDone(source: source, projects: scope.length);
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
    final scope = _scope();
    final wanted = projects.isEmpty || scope.isEmpty ? null : scope.map((e) => e.name).toSet();
    final matches = [
      for (final m in all)
        if (wanted == null || wanted.contains(m.chunk.projectName)) m,
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
