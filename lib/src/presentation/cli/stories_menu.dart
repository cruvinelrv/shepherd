import 'dart:io';
import 'package:shepherd/src/data/datasources/local/shepherd_activity_store.dart';
import '../../data/datasources/local/domains_database.dart';
import 'input_utils.dart';

Future<void> showStoriesMenu(String domain) async {
  final store = ShepherdActivityStore();
  while (true) {
    print('\n--- User Stories & Tasks for domain: $domain ---');
    print('1. Add user story');
    print('2. List user stories');
    print('3. Add task to user story');
    print('4. List tasks of a user story');
    print('9. Back to domain menu');
    print('0. Exit');
    final choice = readLinePrompt('Select an option: ');
    switch (choice) {
      case '1':
        // List available domains for selection
        final db = DomainsDatabase(Directory.current.path);
        final allDomains = await db.getAllDomainHealths();
        await db.close();
        List<String> availableDomains = allDomains.map((d) => d.domainName).toList();
        if (availableDomains.isEmpty) {
          print('No domains registered. Please add a domain first.');
          break;
        }
        print('Available domains:');
        for (final d in availableDomains) {
          print('- $d');
        }
        final domainsInput =
            readLinePrompt('Domains for this story (comma separated, leave blank for ALL): ');
        final domains = (domainsInput == null || domainsInput.trim().isEmpty)
            ? <String>[]
            : domainsInput
                .split(',')
                .map((d) => d.trim())
                .where((d) => d.isNotEmpty && availableDomains.contains(d))
                .toList();

        String? id;
        do {
          id = readLinePrompt('Story ID: ');
          if (id == null || id.trim().isEmpty) {
            print('Story ID is required. Please enter a valid ID.');
          }
        } while (id == null || id.trim().isEmpty);

        String? title;
        do {
          title = readLinePrompt('Title: ');
          if (title == null || title.trim().isEmpty) {
            print('Title is required. Please enter a valid title.');
          }
        } while (title == null || title.trim().isEmpty);

        final description = readLinePrompt('Description (optional): ');
        try {
          await store.logUserStory(
            id: id,
            title: title,
            description: description,
            domains: domains,
            createdBy: Platform.environment['USER'] ?? '',
          );
          print('User story "$title" added.');
        } catch (e) {
          print('Failed to add user story: $e');
        }
        break;
      case '2':
        final stories = await store.listUserStories();
        final filtered = stories.where((s) {
          final ds = (s['domains'] as List?)?.map((e) => e.toString()).toList() ?? [];
          return ds.isEmpty || ds.contains(domain);
        }).toList();
        if (filtered.isEmpty) {
          print('No user stories found for this domain.');
        } else {
          print('User Stories:');
          for (final s in filtered) {
            final ds = (s['domains'] as List?)?.join(', ') ?? '';
            print('- [${s['id']}] ${s['title']} (domains: $ds, status: ${s['status']})');
          }
        }
        break;
      case '3':
        final stories = await store.listUserStories();
        if (stories.isEmpty) {
          print('No user stories available. Add a user story first.');
          break;
        }
        print('Available user stories:');
        for (final s in stories) {
          final ds = (s['domains'] as List?)?.join(', ') ?? '';
          print('- [${s['id']}] ${s['title']} (domains: $ds, status: ${s['status']})');
        }
        String? storyId;
        bool exists = false;
        do {
          storyId = readLinePrompt('Story ID to add task: ');
          exists = stories.any((s) => s['id'] == (storyId ?? ''));
          if (!exists) {
            print('User story with id ${storyId ?? ''} not found. Please choose a valid story.');
          }
        } while (!exists);

        String? taskId;
        do {
          taskId = readLinePrompt('Task ID: ');
          if (taskId == null || taskId.trim().isEmpty) {
            print('Task ID is required. Please enter a valid ID.');
          }
        } while (taskId == null || taskId.trim().isEmpty);

        String? title;
        do {
          title = readLinePrompt('Task title: ');
          if (title == null || title.trim().isEmpty) {
            print('Task title is required. Please enter a valid title.');
          }
        } while (title == null || title.trim().isEmpty);

        final assignee = readLinePrompt('Assignee (optional): ');
        final description = readLinePrompt('Description (optional): ');
        try {
          await store.logTask(
            storyId: storyId ?? '',
            id: taskId,
            title: title,
            assignee: assignee,
            description: description,
          );
          print('Task "$title" added to story $storyId.');
        } catch (e) {
          print('Failed to add task: $e');
        }
        break;
      case '4':
        final storyId = readLinePrompt('Story ID to list tasks: ');
        final tasks = await store.listTasks(storyId ?? '');
        if (tasks.isEmpty) {
          print('No tasks found for story $storyId.');
        } else {
          print('Tasks:');
          for (final t in tasks) {
            print(
                '- [${t['id']}] ${t['title']} (status: ${t['status']}, assignee: ${t['assignee']})');
          }
        }
        break;
      case '9':
        return;
      case '0':
        exit(0);
      default:
        print('Invalid option.');
    }
  }
}
