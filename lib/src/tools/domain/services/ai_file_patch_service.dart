import 'dart:io';
import 'package:path/path.dart' as p;
import '../entities/ai_file_action_entity.dart';
import '../../data/models/ai_file_action_model.dart';
import '../../../utils/ansi_colors.dart';

/// Service responsible for parsing AI proposed file changes, displaying colored diff previews,
/// and safely applying modifications to the local project workspace.
class AiFilePatchService {
  /// Extracts file creation or modification actions from text responses.
  /// Recognizes code fences with `// FILE: <path>` or markdown headers `### File: <path>`.
  static List<AiFileActionEntity> extractActions(String text) {
    final actions = <AiFileActionEntity>[];

    // Pattern 1: Code fences with // FILE: path/to/file or // file: path/to/file
    // Example:
    // ```dart
    // // FILE: lib/main.dart
    // void main() {}
    // ```
    final fileFencePattern = RegExp(
      r'```[a-zA-Z0-9_\-]*\r?\n(?:\/\/|#|\/\*|<!--)\s*(?:FILE|file|ARQUIVO|arquivo):\s*([^\r\n*]+?)(?:\s*\*\/|-->)?\r?\n([\s\S]*?)```',
      multiLine: true,
    );

    for (final match in fileFencePattern.allMatches(text)) {
      final rawPath = match.group(1)?.trim();
      final content = match.group(2);
      if (rawPath != null && rawPath.isNotEmpty && content != null) {
        final path = rawPath.replaceAll('\\', '/');
        final exists = File(path).existsSync();
        actions.add(AiFileActionModel(
          path: path,
          actionType: exists ? AiFileActionType.modify : AiFileActionType.create,
          newContent: content,
          originalContent: exists ? File(path).readAsStringSync() : null,
        ));
      }
    }

    return actions;
  }

  /// Computes a colored unified diff preview for terminal display.
  static String formatColoredDiff({
    required String filePath,
    required String? originalContent,
    required String newContent,
  }) {
    final buffer = StringBuffer();
    final isNew = originalContent == null;

    buffer.writeln('${AnsiColors.bold}${AnsiColors.brightCyan}--- $filePath ${isNew ? "(novo arquivo)" : "(modificação)"}${AnsiColors.reset}');

    final originalLines = (originalContent ?? '').split('\n');
    final newLines = newContent.split('\n');

    if (isNew) {
      for (final line in newLines) {
        buffer.writeln('${AnsiColors.brightGreen}+ $line${AnsiColors.reset}');
      }
    } else {
      // Basic line-by-line diff display
      final maxLines = originalLines.length > newLines.length ? originalLines.length : newLines.length;
      for (var i = 0; i < maxLines; i++) {
        final oldLine = i < originalLines.length ? originalLines[i] : null;
        final newLine = i < newLines.length ? newLines[i] : null;

        if (oldLine == newLine && oldLine != null) {
          // Unchanged line
          if (maxLines < 40 || i < 3 || i >= maxLines - 3) {
            buffer.writeln('  $oldLine');
          } else if (i == 3) {
            buffer.writeln('${AnsiColors.gray}  ...${AnsiColors.reset}');
          }
        } else {
          if (oldLine != null) {
            buffer.writeln('${AnsiColors.brightRed}- $oldLine${AnsiColors.reset}');
          }
          if (newLine != null) {
            buffer.writeln('${AnsiColors.brightGreen}+ $newLine${AnsiColors.reset}');
          }
        }
      }
    }

    return buffer.toString();
  }

  /// Safely applies a file action to the disk within [basePath] (defaults to current directory).
  /// Rejects paths attempting to escape the project root.
  static bool applyAction(AiFileActionEntity action, {String? basePath}) {
    final root = basePath ?? Directory.current.path;
    final normalized = p.normalize(action.path);

    // Prevent directory traversal escaping workspace
    if (normalized.startsWith('..') || p.isAbsolute(normalized) && !normalized.startsWith(root)) {
      stderr.writeln('❌ Caminho de arquivo rejeitado por segurança (fora do workspace): ${action.path}');
      return false;
    }

    final fullPath = p.isAbsolute(normalized) ? normalized : p.join(root, normalized);
    final file = File(fullPath);

    try {
      if (action.actionType == AiFileActionType.delete) {
        if (file.existsSync()) {
          file.deleteSync();
        }
        return true;
      }

      if (action.newContent != null) {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(action.newContent!);
        return true;
      }
    } catch (e) {
      stderr.writeln('❌ Erro ao gravar arquivo $fullPath: $e');
      return false;
    }

    return false;
  }

  /// Interactive helper: presents diff preview for each action and prompts developer confirmation.
  static Future<int> promptAndApply(List<AiFileActionEntity> actions, {String? basePath, bool autoApprove = false}) async {
    if (actions.isEmpty) return 0;

    var appliedCount = 0;
    for (final action in actions) {
      if (action.newContent == null && action.actionType != AiFileActionType.delete) continue;

      print('\n${AnsiColors.bold}📝 Alteração proposta pela IA:${AnsiColors.reset}');
      final diffOutput = formatColoredDiff(
        filePath: action.path,
        originalContent: action.originalContent ?? (File(action.path).existsSync() ? File(action.path).readAsStringSync() : null),
        newContent: action.newContent ?? '',
      );
      print(diffOutput);

      var approve = autoApprove;
      if (!approve) {
        stdout.write('Deseja aplicar esta alteração em ${AnsiColors.brightCyan}${action.path}${AnsiColors.reset}? [S/n]: ');
        final answer = stdin.readLineSync()?.trim().toLowerCase();
        approve = answer == null || answer.isEmpty || answer == 's' || answer == 'sim' || answer == 'y' || answer == 'yes';
      }

      if (approve) {
        final ok = applyAction(action, basePath: basePath);
        if (ok) {
          print('✅ ${AnsiColors.brightGreen}${action.path}${AnsiColors.reset} atualizado com sucesso!\n');
          appliedCount++;
        }
      } else {
        print('⏭️  Alteração em ${action.path} ignorada.\n');
      }
    }

    return appliedCount;
  }
}
