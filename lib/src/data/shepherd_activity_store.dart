import 'dart:io';
import 'package:yaml/yaml.dart';

/// Handles reading and writing activity logs to shepherd_activity.yaml
class ShepherdActivityStore {
  /// Registers a new user story in shepherd_activity.yaml
  Future<void> logUserStory({
    required String id,
    required String title,
    String? description,
    required String domain,
    String status = 'open',
    String? createdBy,
    DateTime? createdAt,
  }) async {
    await logActivity({
      'type': 'user_story',
      'id': id,
      'title': title,
      'description': description ?? '',
      'domain': domain,
      'status': status,
      'created_by': createdBy ?? '',
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'tasks': <Map<String, dynamic>>[],
    });
  }

  /// Registers a new task linked to a user story in shepherd_activity.yaml
  Future<void> logTask({
    required String storyId,
    required String id,
    required String title,
    String? description,
    String status = 'open',
    String? assignee,
    DateTime? createdAt,
  }) async {
    // Read all activities
    final activities = await readActivities();
    // Find the user story
    final idx = activities.indexWhere((a) => a['type'] == 'user_story' && a['id'] == storyId);
    if (idx == -1) {
      throw Exception('User story with id $storyId not found');
    }
    final story = activities[idx];
    final tasks = (story['tasks'] as List?) ?? [];
    tasks.add({
      'id': id,
      'title': title,
      'description': description ?? '',
      'status': status,
      'assignee': assignee ?? '',
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    });
    story['tasks'] = tasks;
    activities[idx] = story;
    // Overwrite the file
    final file = File(activityFilePath);
    final yamlString = _toYamlString(activities);
    await file.writeAsString(yamlString);
  }

  /// Lists all user stories
  Future<List<Map<String, dynamic>>> listUserStories() async {
    final activities = await readActivities();
    return activities.where((a) => a['type'] == 'user_story').toList();
  }

  /// Lists all tasks for a given user story
  Future<List<Map<String, dynamic>>> listTasks(String storyId) async {
    final stories = await listUserStories();
    final story = stories.firstWhere((s) => s['id'] == storyId, orElse: () => {});
    if (story.isEmpty) return [];
    return List<Map<String, dynamic>>.from(story['tasks'] ?? []);
  }

  final String activityFilePath;

  ShepherdActivityStore({this.activityFilePath = 'shepherd_activity.yaml'});

  /// Appends a new activity entry to the shepherd_activity.yaml file.
  Future<void> logActivity(Map<String, dynamic> activity) async {
    final file = File(activityFilePath);
    List<dynamic> activities = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.trim().isNotEmpty) {
        final loaded = loadYaml(content);
        if (loaded is YamlList) {
          activities = List<dynamic>.from(loaded);
        }
      }
    }
    activities.add(activity);
    final yamlString = _toYamlString(activities);
    await file.writeAsString(yamlString);
  }

  /// Reads all activity entries from shepherd_activity.yaml
  Future<List<Map<String, dynamic>>> readActivities() async {
    final file = File(activityFilePath);
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    final loaded = loadYaml(content);
    if (loaded is YamlList) {
      return List<Map<String, dynamic>>.from(
        loaded.map((e) => Map<String, dynamic>.from(e)),
      );
    }
    return [];
  }

  /// Converts a Dart object to a YAML string.
  String _toYamlString(List<dynamic> activities) {
    // Simple YAML serialization for list of maps
    final buffer = StringBuffer();
    for (final entry in activities) {
      buffer.writeln('-');
      (entry as Map<String, dynamic>).forEach((key, value) {
        buffer.writeln('  $key: ${_yamlValue(value)}');
      });
    }
    return buffer.toString();
  }

  String _yamlValue(dynamic value) {
    if (value is String) {
      return '"${value.replaceAll('"', '"')}"';
    } else if (value is num || value is bool) {
      return value.toString();
    } else if (value is List) {
      return '[${value.map(_yamlValue).join(', ')}]';
    } else if (value is Map) {
      return '{${value.entries.map((e) => '${e.key}: ${_yamlValue(e.value)}').join(', ')}}';
    } else if (value == null) {
      return 'null';
    }
    return value.toString();
  }
}

/// Example usage:
/// final store = ShepherdActivityStore();
/// await store.logActivity({
///   'timestamp': DateTime.now().toIso8601String(),
///   'type': 'pr_created',
///   'user': 'alice',
///   'domain': 'payments',
///   'details': {'pr_id': 123, 'title': 'Fix bug'},
/// });
/// final activities = await store.readActivities();
