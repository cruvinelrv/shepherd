import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shepherd/src/utils/shepherd_regex.dart';
import 'package:shepherd/src/domains/data/datasources/local/shepherd_activity_store.dart';

class TagGenerationService {
  final _activityStore = ShepherdActivityStore();

  Future<void> scanAndGenerate({String? storyId}) async {
    print('🔍 Scanning for ShepherdPageTags and User Stories...');

    // 1. Discovery & Registration
    final discoveredIds = await _scanForPageTags();
    await _registerNewStories(discoveredIds);

    // 2. Generation
    final stories = await _activityStore.readActivities();
    final targetStories =
        stories.where((s) => s['type'] == 'user_story').toList();

    List<Map<String, dynamic>> storiesToProcess;
    if (storyId != null) {
      storiesToProcess = targetStories
          .where((s) => s['id'] == storyId)
          .cast<Map<String, dynamic>>()
          .toList();
    } else {
      storiesToProcess = targetStories.cast<Map<String, dynamic>>().toList();
    }

    if (storiesToProcess.isEmpty) {
      print('⚠️ No stories found to generate tags for.');
      return;
    }

    for (final story in storiesToProcess) {
      await _generateTagWrapper(story);
    }

    print('\n🎉 Tag generation completed!');
  }

  Future<Set<String>> _scanForPageTags() async {
    final ids = <String>{};
    final root = Directory.current;

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (entity.path.contains('/.dart_tool/') ||
            entity.path.contains('/.git/')) {
          continue;
        }

        final content = await entity.readAsString();
        final matches = ShepherdRegex.shepherdPageTag.allMatches(content);
        for (final match in matches) {
          ids.add(match.group(1)!);
        }
      }
    }
    return ids;
  }

  Future<void> _registerNewStories(Set<String> discoveredIds) async {
    final existingStories = await _activityStore.readActivities();
    final existingIds = existingStories
        .where((s) => s['type'] == 'user_story')
        .map((s) => s['id'] as String)
        .toSet();

    for (final id in discoveredIds) {
      if (!existingIds.contains(id)) {
        print('🆕 Auto-registering discovered story: $id');
        await _activityStore.logUserStory(
          id: id,
          title: 'Auto-discovered: $id',
          description:
              'Story automatically registered by Shepherd CLI discovery.',
        );
      }
    }
  }

  Future<void> _generateTagWrapper(Map<String, dynamic> story) async {
    final id = story['id'] as String;
    final title = story['title'] as String;
    final tasks = (story['tasks'] as List?) ?? [];
    final elements = (story['elements'] as List?) ?? [];

    // Try to find a meaningful path. For now, we'll use a standardized location
    // or try to find where the ShepherdPageTag was found.
    // For simplicity in this first version, we'll put it in lib/shepherd_tags/ (or similar)
    // but the user's sidenow_web has them next to pages.
    // Let's try to find if a tag already exists, or put it in a 'tags' subfolder of the first found page.
    final targetInfo = await _determineTargetInfo(id);
    final targetPath = targetInfo.path;
    final baseName = targetInfo.baseName;

    final file = File(targetPath);

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    final className = _toPascalCase(baseName) + 'Tags';

    final buffer = StringBuffer();
    buffer.writeln("import 'package:shepherd_tag/shepherd_tag.dart';");
    buffer.writeln();
    buffer.writeln("@ShepherdTag(id: '$id', description: '$title')");
    buffer.writeln("class $className {");

    if (elements.isEmpty && tasks.isEmpty) {
      buffer.writeln("  // TODO: Add interaction constants here");
      buffer.writeln("  // static const String exampleField = 'example_id';");
    } else {
      // Prioritize elements for standard generation
      if (elements.isNotEmpty) {
        for (final element in elements) {
          final elementTitle = element['title'] as String;
          final elementId =
              element['id'] as String? ?? _toSnakeCase(elementTitle);
          final type = element['typeDesignElement'] as String? ?? 'element';

          final constName = _toCamelCase(elementTitle);
          buffer.writeln("  /// Category: $type");
          buffer.writeln("  static const String $constName = '$elementId';");
        }
      }

      // If there are tasks but no elements, or as additional info
      if (tasks.isNotEmpty && elements.isEmpty) {
        buffer.writeln("  // Generated from Tasks (Fallback)");
        for (final task in tasks) {
          final taskTitle = task['title'] as String;
          final constName = _toCamelCase(taskTitle);
          final constValue = _toSnakeCase(taskTitle);
          buffer.writeln("  static const String $constName = '$constValue';");
        }
      }
    }

    buffer.writeln("}");

    await file.writeAsString(buffer.toString());
    print('✅ Generated Tag Wrapper: $targetPath');
  }

  Future<({String path, String baseName})> _determineTargetInfo(
      String id) async {
    final root = Directory.current;

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (entity.path.contains('/.dart_tool/') ||
            entity.path.contains('/.git/')) {
          continue;
        }
        final content = await entity.readAsString();
        if (content.contains("'${id}'") || content.contains('"${id}"')) {
          if (ShepherdRegex.shepherdPageTag.hasMatch(content)) {
            // Found the file using this ID in a ShepherdPageTag
            // Try to extract the class name from this file
            final classMatch =
                RegExp(r'class\s+([a-zA-Z0-9_]+)').firstMatch(content);
            String baseName = id.toLowerCase().replaceAll('-', '_');

            if (classMatch != null) {
              String name = classMatch.group(1)!;

              // If it's a State class, we MUST find the parent StatefulWidget name
              if (name.startsWith('_') && name.endsWith('State')) {
                final parentMatch = RegExp(
                        r'class\s+([a-zA-Z0-9_]+)\s+extends\s+StatefulWidget')
                    .firstMatch(content);
                if (parentMatch != null) {
                  name = parentMatch.group(1)!;
                } else {
                  // Alternative: find the first public class that might be the host
                  final publicClassMatch =
                      RegExp(r'class\s+([a-zA-Z][a-zA-Z0-9_]*)')
                          .firstMatch(content);
                  if (publicClassMatch != null) {
                    name = publicClassMatch.group(1)!;
                  }
                }
              }
              baseName = _toSnakeCase(name);
            }

            final fileName = '${baseName}_tags.dart';
            return (
              path: p.join(p.dirname(entity.path), fileName),
              baseName: baseName
            );
          }
        }
      }
    }

    // Fallback
    final baseName = id.toLowerCase().replaceAll('-', '_');
    return (
      path: p.join('lib', 'shepherd_tags', '${baseName}_tags.dart'),
      baseName: baseName
    );
  }

  String _toPascalCase(String text) {
    return text
        .split(RegExp(r'[-_ ]'))
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join();
  }

  String _toCamelCase(String text) {
    final pascal = _toPascalCase(text);
    if (pascal.isEmpty) return '';
    return pascal[0].toLowerCase() + pascal.substring(1);
  }

  String _toSnakeCase(String text) {
    if (text.isEmpty) return '';

    // Handle PascalCase by adding underscores before uppercase letters
    final result = text.replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (match) {
      return '${match.group(1)}_${match.group(2)}';
    });

    return result
        .split(RegExp(r'[-_ ]'))
        .where((s) => s.isNotEmpty)
        .map((s) => s.toLowerCase())
        .join('_');
  }
}
