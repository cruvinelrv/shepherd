import 'dart:io';
import 'package:shepherd/src/utils/shepherd_regex.dart';
import 'package:shepherd/src/domains/data/datasources/local/shepherd_activity_store.dart';

class ShepherdTagInfo {
  final String id;
  final String? title;
  final String? description;
  final String filePath;
  final Map<String, String> actions;
  final List<String> tasks;
  final List<Map<String, dynamic>> elements;

  ShepherdTagInfo({
    required this.id,
    this.title,
    this.description,
    required this.filePath,
    this.actions = const {},
    this.tasks = const [],
    this.elements = const [],
  });
}

class TestGenerationService {
  final _activityStore = ShepherdActivityStore();

  Future<void> generateFlows({String? storyId}) async {
    print('🔍 Scanning for Shepherd Tags...');

    final tags = await _scanProject();

    if (tags.isEmpty) {
      print('⚠️  No @ShepherdTag found in the project.');
      return;
    }

    final filteredTags = storyId != null ? tags.where((t) => t.id == storyId).toList() : tags;

    if (filteredTags.isEmpty) {
      print('⚠️  No @ShepherdTag found for story ID: $storyId');
      return;
    }

    print('📦 Found ${filteredTags.length} tag(s). Generating Maestro flows...');

    for (final tag in filteredTags) {
      await _generateMaestroFlow(tag);
    }

    print('\n🎉 Generation completed!');
  }

  Future<List<ShepherdTagInfo>> _scanProject() async {
    final tagsMap = <String, ShepherdTagInfo>{};
    final root = Directory.current;

    // Fetch registered stories from activity store
    final registeredStories = await _activityStore.readActivities();

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (entity.path.contains('/.dart_tool/') || entity.path.contains('/.git/')) {
          continue;
        }

        final content = await entity.readAsString();

        // Scan for @ShepherdTag
        final tagMatches = ShepherdRegex.shepherdTag.allMatches(content);
        for (final match in tagMatches) {
          final id = match.group(1)!;

          // Look for associated class members if tag is on a class
          final Map<String, String> actions = {};
          final classStartIndex = match.end;
          final classContent = content.substring(classStartIndex);

          // Find class body
          final classBodyMatch = RegExp(r"class\s+\w+\s*\{").firstMatch(classContent);
          if (classBodyMatch != null) {
            final bodyStartIndex = classBodyMatch.end;
            // Simple brace counting to find class end
            int braceCount = 1;
            int bodyEndIndex = bodyStartIndex;
            while (braceCount > 0 && bodyEndIndex < classContent.length) {
              if (classContent[bodyEndIndex] == '{') braceCount++;
              if (classContent[bodyEndIndex] == '}') braceCount--;
              bodyEndIndex++;
            }

            final body = classContent.substring(bodyStartIndex, bodyEndIndex);
            for (final memberMatch in ShepherdRegex.classMember.allMatches(body)) {
              actions[memberMatch.group(1)!] = memberMatch.group(2)!;
            }
          }

          // Try to enrich from Activity Store
          final storyData = registeredStories.firstWhere(
            (a) => a['type'] == 'user_story' && a['id'] == id,
            orElse: () => {},
          );

          final tasks =
              (storyData['tasks'] as List?)?.map((t) => (t as Map)['title'] as String).toList() ??
                  [];
          final elements = (storyData['elements'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          tagsMap[id] = ShepherdTagInfo(
            id: id,
            title: storyData['title'] as String?,
            description: storyData['description'] as String? ?? match.group(2),
            filePath: entity.path,
            actions: actions,
            tasks: tasks,
            elements: elements,
          );
        }

        // Scan for ShepherdPageKey
        final pageMatches = ShepherdRegex.shepherdPageKey.allMatches(content);
        for (final match in pageMatches) {
          final id = match.group(1)!;
          if (!tagsMap.containsKey(id)) {
            // Try to enrich from Activity Store
            final storyData = registeredStories.firstWhere(
              (a) => a['type'] == 'user_story' && a['id'] == id,
              orElse: () => {},
            );

            final tasks =
                (storyData['tasks'] as List?)?.map((t) => (t as Map)['title'] as String).toList() ??
                    [];
            final elements = (storyData['elements'] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();

            tagsMap[id] = ShepherdTagInfo(
              id: id,
              title: storyData['title'] as String?,
              description: storyData['description'] as String?,
              filePath: entity.path,
              tasks: tasks,
              elements: elements,
            );
          }
        }
      }
    }

    return tagsMap.values.toList();
  }

  Future<void> _generateMaestroFlow(ShepherdTagInfo tag) async {
    final flowsDir = Directory('.shepherd/maestro/flows');
    if (!await flowsDir.exists()) {
      await flowsDir.create(recursive: true);
    }

    final fileName = '${tag.id.toLowerCase().replaceAll('-', '_')}_flow.yaml';
    final file = File('${flowsDir.path}/$fileName');

    final isWeb = Directory('web').existsSync();
    final buffer = StringBuffer();
    if (isWeb) {
      buffer.writeln('url: \${APP_ID}');
    } else {
      buffer.writeln('appId: \${APP_ID}');
    }
    buffer.writeln('---');
    buffer.writeln('- launchApp');
    if (isWeb) {
      buffer.writeln('- assertVisible:');
      buffer.writeln('    label: "shepherd:${tag.id}"');
    } else {
      buffer.writeln('- assertVisible: "shepherd:${tag.id}"');
    }
    if (tag.title != null || tag.description != null) {
      buffer.writeln('\n# Story: ${tag.title ?? tag.id}');
      if (tag.description != null) {
        buffer.writeln('# Description: ${tag.description}');
      }
    }

    if (tag.tasks.isNotEmpty) {
      buffer.writeln('# Registered Tasks:');
      for (final task in tag.tasks) {
        buffer.writeln('# - $task');
      }
    }

    if (tag.elements.isNotEmpty) {
      buffer.writeln('\n# Interaction Elements (from Atomic Design schema):');
      for (final element in tag.elements) {
        final id = element['id'] as String;
        final type = (element['typeDesignElement'] as String?)?.toLowerCase();

        if (type == 'atom') {
          if (id.contains('input') || id.contains('field')) {
            if (isWeb) {
              buffer.writeln('- tapOn:');
              buffer.writeln('    label: "$id"');
            } else {
              buffer.writeln('- tapOn: "$id"');
            }
            buffer.writeln('- inputText: "sample data"');
          } else if (id.contains('btn') || id.contains('button') || id.contains('tap')) {
            if (isWeb) {
              buffer.writeln('- tapOn:');
              buffer.writeln('    label: "$id"');
            } else {
              buffer.writeln('- tapOn: "$id"');
            }
          } else {
            if (isWeb) {
              buffer.writeln('- assertVisible:');
              buffer.writeln('    label: "$id"');
            } else {
              buffer.writeln('- assertVisible: "$id"');
            }
          }
        } else if (type == 'molecule' || type == 'organism') {
          if (isWeb) {
            buffer.writeln('- assertVisible:');
            buffer.writeln('    label: "$id"');
          } else {
            buffer.writeln('- assertVisible: "$id"');
          }
        } else {
          if (isWeb) {
            buffer.writeln('- assertVisible:');
            buffer.writeln('    label: "$id"');
          } else {
            buffer.writeln('- assertVisible: "$id"');
          }
        }
      }
    } else if (tag.actions.isNotEmpty) {
      buffer.writeln('\n# Automatic Steps (from @ShepherdTag constants):');
      for (final entry in tag.actions.entries) {
        final key = entry.key.toLowerCase();
        final value = entry.value;

        if (key.contains('button') || key.contains('clickable') || key.contains('tap')) {
          if (isWeb) {
            buffer.writeln('- tapOn:');
            buffer.writeln('    label: "$value"');
          } else {
            buffer.writeln('- tapOn: "$value"');
          }
        } else if (key.contains('field') || key.contains('input')) {
          if (isWeb) {
            buffer.writeln('- tapOn:');
            buffer.writeln('    label: "$value"');
          } else {
            buffer.writeln('- tapOn: "$value"');
          }
          buffer.writeln('- inputText: "sample data"');
        } else {
          if (isWeb) {
            buffer.writeln('- assertVisible:');
            buffer.writeln('    label: "$value"');
          } else {
            buffer.writeln('- assertVisible: "$value"');
          }
        }
      }
    }

    await file.writeAsString(buffer.toString());
    print('✅ Generated: .shepherd/maestro/flows/$fileName');
  }
}
