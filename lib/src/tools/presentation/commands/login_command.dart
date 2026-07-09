import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:yaml_writer/yaml_writer.dart';
import 'package:yaml/yaml.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

Future<void> runLoginCommand(List<String> arguments) async {
  final parser = ArgParser();
  parser.addOption('env',
      allowed: ['prod', 'uat'], defaultsTo: 'prod', help: 'Target environment');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print('❌ Error: ${e.toString()}');
    print('Usage: shepherd login [--env prod|uat]');
    return;
  }

  // We keep the flag as an optional override for CI/CD, but if not passed or invalid, we prompt.
  String env = argResults['env'] as String;

  if (!argResults.wasParsed('env')) {
    print('\\nSelect the target environment:');
    print('[1] Production (union.shepherdplatform.com)');
    print('[2] UAT (union-uat.shepherdplatform.com)');
    stdout.write('Select a number (1-2) [default 1]: ');
    final envSelection = stdin.readLineSync();
    if (envSelection == '2') {
      env = 'uat';
    } else {
      env = 'prod';
    }
  }

  print("\\nConnecting to ${env == 'uat' ? 'UAT' : 'Production'}...");

  stdout.write('Email: ');
  final email = stdin.readLineSync();

  if (email == null || email.trim().isEmpty) {
    print('❌ Error: Email is required.');
    return;
  }

  stdout.write('Password: ');
  stdin.echoMode = false;
  final password = stdin.readLineSync();
  stdin.echoMode = true;
  print(''); // Print a newline since echoMode was off

  if (password == null || password.isEmpty) {
    print('❌ Error: Password is required.');
    return;
  }

  print('⏳ Authenticating...');
  final bffUrl = env == 'uat'
      ? 'https://union-uat.shepherdplatform.com/graphql'
      : 'https://union.shepherdplatform.com/graphql';

  const loginQuery = """
    mutation Login(\$email: String!, \$password: String!) {
      login(email: \$email, password: \$password) {
        token
        corporationId
      }
    }
  """;

  try {
    final response = await http.post(
      Uri.parse(bffUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': loginQuery,
        'variables': {
          'email': email.trim(),
          'password': password,
        }
      }),
    );

    if (response.statusCode != 200) {
      print('❌ Login failed with status: ${response.statusCode}');
      return;
    }

    final body = jsonDecode(response.body);
    if (body['errors'] != null) {
      print('❌ Login failed: ${body["errors"][0]["message"]}');
      return;
    }

    final data = body['data']?['login'];
    if (data == null || data['token'] == null) {
      print('❌ Login failed: Invalid credentials.');
      return;
    }

    final token = data['token'];
    final corporationId = data['corporationId'];
    _saveGlobalSession(token, env, corporationId);
    print('✅ Authentication successful!');

    // Now fetch projects
    print('⏳ Fetching your projects...');
    const projectsQuery = """
      query {
        projects {
          id
          name
        }
      }
    """;

    final projResponse = await http.post(
      Uri.parse(bffUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        if (corporationId != null) 'X-Corporation-Id': corporationId,
      },
      body: jsonEncode({'query': projectsQuery}),
    );

    if (projResponse.statusCode != 200) {
      print(
          '⚠️ Could not fetch projects (status: ${projResponse.statusCode}). Link your project manually later.');
      return;
    }

    final projBody = jsonDecode(projResponse.body);
    if (projBody['errors'] != null) {
      print('⚠️ Error fetching projects: ${projBody["errors"][0]["message"]}');
      return;
    }

    final projects = projBody['data']?['projects'] as List<dynamic>?;
    if (projects == null || projects.isEmpty) {
      print(
          '⚠️ You have no projects. Create one in the Shepherd Platform first.');
      return;
    }

    print('\nWhich project is this folder connected to?');
    for (int i = 0; i < projects.length; i++) {
      print('[${i + 1}] ${projects[i]["name"]}');
    }

    stdout.write('Select a number (1-${projects.length}): ');
    final selectionStr = stdin.readLineSync();
    final selection = int.tryParse(selectionStr ?? '');

    if (selection == null || selection < 1 || selection > projects.length) {
      print('❌ Invalid selection. Aborting.');
      return;
    }

    final selectedProject = projects[selection - 1];
    _saveLocalProject(selectedProject['id']);
    print(
        '✅ Project "${selectedProject["name"]}" linked successfully to this folder!');

    // Sincroniza ambientes
    await _syncEnvironments(selectedProject['id'], token, bffUrl, corporationId);
  } catch (e) {
    print('❌ Connection error: $e');
  }
}

Future<void> _syncEnvironments(String projectId, String token, String bffUrl, String? corporationId) async {
  print('⏳ Synchronizing environments with Shepherd Union...');
  final envFile = File('.shepherd/environments.yaml');
  Map<String, dynamic> localEnvs = {};

  if (envFile.existsSync()) {
    final content = envFile.readAsStringSync();
    if (content.trim().isNotEmpty) {
      final loaded = loadYaml(content);
      if (loaded is YamlMap) {
        localEnvs = Map<String, dynamic>.from(loaded);
      }
    }
  }

  // Prepara payload pro BFF
  final List<Map<String, String>> inputEnvs = [];
  localEnvs.forEach((name, branch) {
    inputEnvs.add({'name': name, 'branch': branch.toString()});
  });

  const syncMutation = """
    mutation SyncEnvironments(\$projectId: ID!, \$input: [SyncEnvironmentInput]!) {
      syncProjectEnvironments(projectId: \$projectId, input: \$input) {
        environment {
          name
        }
        branch
        apiKey
      }
    }
  """;

  try {
    final response = await http.post(
      Uri.parse(bffUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer \$token',
        if (corporationId != null) 'X-Corporation-Id': corporationId,
      },
      body: jsonEncode({
        'query': syncMutation,
        'variables': {
          'projectId': projectId,
          'input': inputEnvs,
        }
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['errors'] == null) {
        final syncedList = body['data']?['syncProjectEnvironments'] as List<dynamic>?;
        if (syncedList != null) {
          // Atualiza o arquivo local
          Map<String, String> updatedEnvs = {};
          for (var item in syncedList) {
            final name = item['environment']['name'];
            final branch = item['branch'] ?? 'main';
            updatedEnvs[name] = branch;
          }
          if (!envFile.parent.existsSync()) {
            envFile.parent.createSync(recursive: true);
          }
          final yamlWriter = YamlWriter();
          final yamlString = yamlWriter.write(updatedEnvs);
          envFile.writeAsStringSync(yamlString);
          print('✅ Environments synchronized successfully!');
        }
      } else {
        print('⚠️ Error syncing environments: \${body["errors"][0]["message"]}');
      }
    }
  } catch (e) {
    print('⚠️ Could not sync environments: \$e');
  }
}

void _saveGlobalSession(String token, String env, String? corporationId) {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) {
    print('⚠️ Could not find HOME directory to save global session.');
    return;
  }
  final cliDir = Directory(p.join(home, '.shepherd_cli'));
  if (!cliDir.existsSync()) {
    cliDir.createSync(recursive: true);
  }

  final sessionFile = File(p.join(cliDir.path, 'session.yaml'));
  Map<String, dynamic> configMap = {};

  if (sessionFile.existsSync()) {
    final content = sessionFile.readAsStringSync();
    if (content.trim().isNotEmpty) {
      final loaded = loadYaml(content);
      if (loaded is YamlMap) {
        configMap = Map<String, dynamic>.from(loaded);
      }
    }
  }

  configMap['token'] = token;
  configMap['env'] = env;
  if (corporationId != null) {
    configMap['corporationId'] = corporationId;
  }
  final yamlWriter = YamlWriter();
  final yamlString = yamlWriter.write(configMap);
  sessionFile.writeAsStringSync(yamlString);
}

void _saveLocalProject(String projectId) {
  final shepherdDir = Directory('.shepherd');
  if (!shepherdDir.existsSync()) {
    shepherdDir.createSync(recursive: true);
  }

  final configFile = File('.shepherd/config.yaml');
  Map<String, dynamic> configMap = {};

  if (configFile.existsSync()) {
    final content = configFile.readAsStringSync();
    if (content.trim().isNotEmpty) {
      final loaded = loadYaml(content);
      if (loaded is YamlMap) {
        configMap = Map<String, dynamic>.from(loaded);
      }
    }
  }

  configMap['project_id'] = projectId;
  // We remove any legacy api_key or token if they exist
  configMap.remove('api_key');
  configMap.remove('token');

  final yamlWriter = YamlWriter();
  final yamlString = yamlWriter.write(configMap);
  configFile.writeAsStringSync(yamlString);
}
