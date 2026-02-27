import 'dart:io';
import 'package:shepherd/src/domains/data/datasources/local/shepherd_activity_store.dart';

/// CLI command to add a new user story
Future<void> runAddStoryCommand(List<String> args) async {
  if (args.length < 3) {
    print(
        'Usage: shepherd story add <id> <title> <domains(comma separated)> [description]');
    return;
  }
  final id = args[0];
  final title = args[1];
  final domainsInput = args[2];
  final domains = domainsInput
      .split(',')
      .map((d) => d.trim())
      .where((d) => d.isNotEmpty)
      .toList();
  final description = args.length > 3 ? args.sublist(3).join(' ') : '';
  final store = ShepherdActivityStore();
  await store.logUserStory(
    id: id,
    title: title,
    domains: domains,
    description: description,
    createdBy: Platform.environment['USER'] ?? '',
  );
  print('User story "$title" added.');
}

/// CLI command to list all user stories
Future<void> runListStoriesCommand(List<String> args) async {
  final store = ShepherdActivityStore();
  final stories = await store.listUserStories();
  if (stories.isEmpty) {
    print('No user stories found.');
    return;
  }
  print('User Stories:');
  for (final s in stories) {
    final ds = (s['domains'] as List?)?.join(', ') ?? '';
    print(
        '- [${s['id']}] ${s['title']} (domains: $ds, status: ${s['status']})');
  }
}

/// CLI command to add a new task to a user story
Future<void> runAddTaskCommand(List<String> args) async {
  if (args.length < 3) {
    print(
        'Usage: shepherd task add <storyId> <taskId> <title> [assignee] [description]');
    return;
  }
  final storyId = args[0];
  final taskId = args[1];
  final title = args[2];
  final assignee = args.length > 3 ? args[3] : '';
  final description = args.length > 4 ? args.sublist(4).join(' ') : '';
  final store = ShepherdActivityStore();
  try {
    await store.logTask(
      storyId: storyId,
      id: taskId,
      title: title,
      assignee: assignee,
      description: description,
    );
    print('Task "$title" added to story $storyId.');
  } catch (e) {
    print('Error: ${e.toString()}');
  }
}

/// CLI command to list all tasks for a user story
Future<void> runListTasksCommand(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: shepherd task list <storyId>');
    return;
  }
  final storyId = args[0];
  final store = ShepherdActivityStore();
  final tasks = await store.listTasks(storyId);
  if (tasks.isEmpty) {
    print('No tasks found for story $storyId.');
    return;
  }
  print('Tasks for story $storyId:');
  for (final t in tasks) {
    print(
        '- [${t['id']}] ${t['title']} (status: ${t['status']}, assignee: ${t['assignee']})');
  }
}

/// CLI command to add a new design element to a user story
Future<void> runAddElementCommand(List<String> args) async {
  if (args.length < 4) {
    print(
        'Usage: shepherd element add <storyId> <elementId> <title> <type(atom|molecule|organism|token)>');
    return;
  }
  final storyId = args[0];
  final elementId = args[1];
  final title = args[2];
  final type = args[3];
  final store = ShepherdActivityStore();
  try {
    await store.logElement(
      storyId: storyId,
      id: elementId,
      title: title,
      typeDesignElement: type,
    );
    print('Element "$title" added to story $storyId.');
  } catch (e) {
    print('Error: ${e.toString()}');
  }
}

/// CLI command to list all design elements for a user story
Future<void> runListElementsCommand(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: shepherd element list <storyId>');
    return;
  }
  final storyId = args[0];
  final store = ShepherdActivityStore();
  final stories = await store.listUserStories();
  final story = stories.firstWhere((s) => s['id'] == storyId, orElse: () => {});
  if (story.isEmpty) {
    print('User story $storyId not found.');
    return;
  }
  final elements = (story['elements'] as List?) ?? [];
  if (elements.isEmpty) {
    print('No elements found for story $storyId.');
    return;
  }
  print('Design Elements for story $storyId:');
  for (final e in elements) {
    print('- [${e['id']}] ${e['title']} (type: ${e['typeDesignElement']})');
  }
}
