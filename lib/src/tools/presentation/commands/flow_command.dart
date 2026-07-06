import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:shepherd/src/menu/presentation/cli/microfrontends_menu.dart';
import 'package:shepherd/src/tools/domain/services/changelog_service.dart';
import 'package:shepherd/src/utils/shepherd_regex.dart';

/// Runs the complete TBD release flow locally:
/// 1. Verifies that we are on the principal branch and working tree is clean.
/// 2. Bumps the version (reusing Deploy version model for root/microfrontends).
/// 3. Switches to a release/vX.Y.Z branch.
/// 4. Updates version files and CHANGELOG.md.
/// 5. Commits and pushes the release branch.
/// 6. Opens a PR to principal branch using GitHub CLI (gh).
/// 7. Switches back to the principal branch, keeping workspace clean.
Future<void> runFlowCommand(List<String> arguments) async {
  final parser = ArgParser();
  parser.addOption('bump',
      abbr: 'p',
      help: 'Version bump type (keep, patch, minor, major)',
      allowed: ['keep', 'patch', 'minor', 'major']);
  parser.addOption('base',
      abbr: 'b',
      help:
          'Base tag/commit to compare against (default: auto-detected previous tag)');
  parser.addFlag('interactive',
      abbr: 'i', help: 'Prompt for inputs if not specified', defaultsTo: true);
  parser.addFlag('help',
      abbr: 'h', help: 'Show help message', negatable: false);
  // New options for PR handling
  parser.addFlag('no-pr',
      abbr: 'n', help: 'Skip Pull Request creation', defaultsTo: false);
  parser.addOption('pr-title', help: 'Custom PR title');
  parser.addOption('pr-body', help: 'Custom PR body');
  parser.addOption('base-branch',
      help: 'Base branch for PR (default: principal branch)');

  try {
    final results = parser.parse(arguments);
    if (results['help'] == true) {
      print('Usage: shepherd flow [options]');
      print(parser.usage);
      return;
    }
    final service = ChangelogService();
    final projectDir = Directory.current.path;

    // Detect principal branch from environments.yaml or default to main
    final envFile = File('$projectDir/.shepherd/environments.yaml');
    var principalBranch = 'main';
    if (envFile.existsSync()) {
      try {
        final content = envFile.readAsStringSync();
        final map = loadYaml(content);
        if (map is Map) {
          final prdBranch = map['PRD'] ?? map['production'] ?? map['prod'];
          if (prdBranch != null) {
            principalBranch = prdBranch.toString();
          }
        }
      } catch (_) {}
    }

    // 1. Verify Git status and current branch
    final branchResult =
        await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (branchResult.exitCode != 0) {
      print('Error: Directory is not a Git repository.');
      return;
    }
    final currentBranch = (branchResult.stdout as String).trim();
    print('Current branch: $currentBranch');

    if (currentBranch != principalBranch) {
      print(
          'Error: shepherd flow must be executed from the principal branch ($principalBranch).');
      return;
    }

    final statusResult = await Process.run('git', ['status', '--porcelain']);
    if (statusResult.exitCode != 0) {
      print('Error checking Git status.');
      return;
    }
    if ((statusResult.stdout as String).trim().isNotEmpty) {
      print(
          'Error: You have uncommitted changes. Please commit or stash them before running shepherd flow.');
      return;
    }

    // Load current version using deploy model (handling microfrontends)
    final currentVersion = _getCurrentAppVersion(projectDir);
    if (currentVersion == null || currentVersion.isEmpty) {
      print('Error: Could not read version from pubspec.yaml.');
      return;
    }
    print('Current version: $currentVersion');

    // 2. Resolve version bump type
    var bumpType = results['bump'] as String?;
    var newVersion = currentVersion;
    if (bumpType == null && results['interactive'] == true) {
      final patchVer = _bumpVersion(currentVersion, 'patch');
      final minorVer = _bumpVersion(currentVersion, 'minor');
      final majorVer = _bumpVersion(currentVersion, 'major');

      stdout.write('Choose version bump:\n'
          '  1: Keep ($currentVersion)\n'
          '  2: Patch ($patchVer)\n'
          '  3: Minor ($minorVer)\n'
          '  4: Major ($majorVer)\n'
          '  Or enter custom version directly: ');
      final choice = stdin.readLineSync()?.trim();
      if (choice == null || choice.isEmpty || choice == '1') {
        newVersion = currentVersion;
      } else if (choice == '2') {
        newVersion = patchVer;
      } else if (choice == '3') {
        newVersion = minorVer;
      } else if (choice == '4') {
        newVersion = majorVer;
      } else {
        newVersion = choice;
      }
    } else {
      bumpType ??= 'keep';
      if (bumpType != 'keep') {
        newVersion = _bumpVersion(currentVersion, bumpType);
      }
    }
    print('Bumping version to: $newVersion');

    final releaseBranch = 'release/v$newVersion';

    // Check if local release branch already exists, delete if so
    final checkBranch =
        await Process.run('git', ['branch', '--list', releaseBranch]);
    if ((checkBranch.stdout as String).trim().isNotEmpty) {
      print(
          'Warning: Local branch $releaseBranch already exists. Deleting it to start fresh...');
      final delResult =
          await Process.run('git', ['branch', '-D', releaseBranch]);
      if (delResult.exitCode != 0) {
        print(
            'Error deleting existing local branch $releaseBranch: ${delResult.stderr}');
        return;
      }
    }

    // 3. Switch to release branch
    print('Creating and switching to release branch: $releaseBranch...');
    final checkoutResult =
        await Process.run('git', ['checkout', '-b', releaseBranch]);
    if (checkoutResult.exitCode != 0) {
      print('Error creating release branch: ${checkoutResult.stderr}');
      return;
    }

    // 4. Apply version updates
    final updatedVersionFiles = _updateAppVersion(projectDir, newVersion);
    if (updatedVersionFiles.isEmpty) {
      print('Warning: No version files updated.');
    }

    // Resolve base tag/commit
    var base = results['base'] as String?;
    if (base == null || base.isEmpty) {
      final gitResult =
          await Process.run('git', ['describe', '--tags', '--abbrev=0']);
      if (gitResult.exitCode == 0) {
        base = (gitResult.stdout as String).trim();
        if (base == 'v$newVersion' || base == newVersion) {
          final gitResultPrev = await Process.run(
              'git', ['describe', '--tags', '--abbrev=0', 'HEAD^']);
          if (gitResultPrev.exitCode == 0) {
            base = (gitResultPrev.stdout as String).trim();
          }
        }
      } else {
        base = principalBranch;
      }
    }
    print('Comparing commits against base: $base');

    // Update CHANGELOG.md & archive history
    print('Generating changelog for version $newVersion...');
    final updatedPaths = await service.updateChangelog(
      baseBranch: base,
      changelogType: 'change',
      projectDir: projectDir,
    );

    if (updatedPaths.isNotEmpty) {
      print('CHANGELOG.md updated successfully.');
      await service.updateChangelogHeader(newVersion);
    }

    // 5. Stage, Commit & Push Release Branch
    print('Staging changes...');
    final gitAddArgs = ['add', 'CHANGELOG.md'];
    final historyFile = File('$projectDir/dev_tools/changelog_history.md');
    if (historyFile.existsSync()) {
      gitAddArgs.add('dev_tools/changelog_history.md');
    }
    for (final f in updatedVersionFiles) {
      // Get relative path of version file to stage
      final relPath = f.path.replaceFirst('$projectDir/', '');
      gitAddArgs.add(relPath);
    }
    await Process.run('git', gitAddArgs);

    final commitMsg =
        'docs: update CHANGELOG.md and bump version to $newVersion';
    print('Committing: "$commitMsg"...');
    final commitResult = await Process.run('git', ['commit', '-m', commitMsg]);
    if (commitResult.exitCode != 0) {
      print('Commit failed: ${commitResult.stderr}');
      print(
          'Switching back to principal branch and deleting release branch...');
      await Process.run('git', ['checkout', principalBranch]);
      await Process.run('git', ['branch', '-D', releaseBranch]);
      return;
    }
    print('Changes committed successfully.');

    print('Pushing release branch to origin...');
    final pushResult =
        await Process.run('git', ['push', '-u', 'origin', releaseBranch]);
    if (pushResult.exitCode != 0) {
      print('Error pushing release branch: ${pushResult.stderr}');
      print('Switching back to principal branch...');
      await Process.run('git', ['checkout', principalBranch]);
      return;
    }
    print('Branch pushed to origin successfully.');

    // 6. Open Pull Request on GitHub (optional)
    final noPr = results['no-pr'] as bool? ?? false;
    if (!noPr) {
      // Determine PR title: use provided option, otherwise prompt (if interactive) or fallback to default
      String prTitle;
      final providedTitle = results['pr-title'] as String?;
      if (providedTitle != null && providedTitle.isNotEmpty) {
        prTitle = providedTitle;
      } else if (results['interactive'] == true) {
        stdout.write('Enter PR title (default "Release v$newVersion"): ');
        final inputTitle = stdin.readLineSync()?.trim();
        prTitle = (inputTitle == null || inputTitle.isEmpty)
            ? 'Release v$newVersion'
            : inputTitle;
      } else {
        prTitle = 'Release v$newVersion';
      }

      final prBodyOption = results['pr-body'] as String?;
      final baseBranchOption = results['base-branch'] as String?;
      final baseForPr = baseBranchOption ?? principalBranch;
      final remoteUrlResult =
          await Process.run('git', ['remote', 'get-url', 'origin']);
      if (remoteUrlResult.exitCode == 0) {
        final remoteUrl = (remoteUrlResult.stdout as String).trim();
        final match = ShepherdRegex.githubRepo.firstMatch(remoteUrl);
        if (match != null && match.groupCount >= 1) {
          final repository = match.group(1)!;
          // Determine PR body: use custom option, else generate from commits, fallback to changelog notes
          String prBody;
          if (prBodyOption != null && prBodyOption.isNotEmpty) {
            prBody = prBodyOption;
          } else {
            // Generate from commit messages between base and release branch
            final logResult = await Process.run('git',
                ['log', '--pretty=format:* %s', '$baseForPr..$releaseBranch']);
            if (logResult.exitCode == 0 &&
                (logResult.stdout as String).trim().isNotEmpty) {
              prBody = (logResult.stdout as String).trim();
            } else {
              // Fallback to changelog notes if commit log empty
              prBody = _getReleaseNotes(projectDir, newVersion);
            }
          }
          var token = Platform.environment['GITHUB_TOKEN'];
          if (token != null && token.isNotEmpty) {
            // Use GitHub REST API to create PR
            final apiUrl = 'https://api.github.com/repos/$repository/pulls';
            final payload = jsonEncode({
              'title': prTitle,
              'head': releaseBranch,
              'base': baseForPr,
              'body': prBody.isNotEmpty
                  ? prBody
                  : 'Release version v$newVersion generated by Shepherd CLI.',
            });
            final response = await http.post(
              Uri.parse(apiUrl),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/vnd.github.v3+json',
                'Content-Type': 'application/json',
              },
              body: payload,
            );
            if (response.statusCode == 201) {
              print(
                  '\x1B[32mPull Request successfully created via GitHub API!\x1B[0m');
            } else {
              print(
                  '\x1B[31mFailed to create Pull Request via API (status ${response.statusCode}). Falling back to gh CLI...\x1B[0m');
              token = null; // ensure fallback
            }
          }
          // Fallback to gh CLI if token not used or API failed
          if (token == null) {
            final ghCheck = await Process.run('which', ['gh']);
            if (ghCheck.exitCode == 0) {
              final authCheck = await Process.run('gh', ['auth', 'status']);
              if (authCheck.exitCode == 0) {
                print('Creating Pull Request on GitHub using gh CLI...');
                final prResult = await Process.run('gh', [
                  'pr',
                  'create',
                  '--repo',
                  repository,
                  '--head',
                  releaseBranch,
                  '--base',
                  baseForPr,
                  '--title',
                  prTitle,
                  '--body',
                  prBody.isNotEmpty
                      ? prBody
                      : 'Release version v$newVersion generated by Shepherd CLI.',
                ]);
                stdout.write(prResult.stdout);
                stderr.write(prResult.stderr);
                if (prResult.exitCode == 0) {
                  print(
                      '\x1B[32mPull Request successfully created on GitHub!\x1B[0m');
                } else {
                  print(
                      '\x1B[31mFailed to create Pull Request on GitHub. Please create it manually.\x1B[0m');
                }
              } else {
                print(
                    'Warning: You are not authenticated in GitHub CLI (gh). Please run "gh auth login" or create the PR manually.');
                print(
                    'PR URL: https://github.com/$repository/compare/$baseForPr...$releaseBranch');
              }
            } else {
              print(
                  'Warning: GitHub CLI (gh) is not installed. Please create the PR manually.');
              print(
                  'PR URL: https://github.com/$repository/compare/$baseForPr...$releaseBranch');
            }
          }
        }
      }
    }

    // 7. Switch back to principal branch
    print('Switching back to principal branch: $principalBranch...');
    final backResult = await Process.run('git', ['checkout', principalBranch]);
    if (backResult.exitCode != 0) {
      print('Error switching back to $principalBranch: ${backResult.stderr}');
    } else {
      print(
          '✅ Release branch pushed${noPr ? '' : ' and PR opened'}. Back on principal branch $principalBranch.');
    }
  } catch (e) {
    print('Error running release flow: $e');
    exit(1);
  }
}

String? _getCurrentAppVersion(String projectDir) {
  final microfrontends = loadMicrofrontends();
  if (microfrontends.isNotEmpty) {
    final path = microfrontends.first['path']?.toString();
    if (path != null && path.isNotEmpty) {
      final pubspec = File('$projectDir/$path/pubspec.yaml');
      if (pubspec.existsSync()) {
        final lines = pubspec.readAsLinesSync();
        final versionLine = lines.firstWhere(
          (l) => l.trim().startsWith('version:'),
          orElse: () => '',
        );
        if (versionLine.isNotEmpty) {
          return versionLine.split(':').last.trim();
        }
      }
    }
  } else {
    final pubspecFile = File('$projectDir/pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final lines = pubspecFile.readAsLinesSync();
      final versionLine = lines.firstWhere(
        (l) => l.trim().startsWith('version:'),
        orElse: () => '',
      );
      if (versionLine.isNotEmpty) {
        return versionLine.split(':').last.trim();
      }
    }
  }
  return null;
}

List<File> _updateAppVersion(String projectDir, String newVersion) {
  final updatedFiles = <File>[];
  final microfrontends = loadMicrofrontends();
  if (microfrontends.isNotEmpty) {
    for (final m in microfrontends) {
      final path = m['path']?.toString();
      if (path == null || path.isEmpty) continue;
      final pubspec = File('$projectDir/$path/pubspec.yaml');
      if (pubspec.existsSync()) {
        final lines = pubspec.readAsLinesSync();
        final newLines = lines.map((line) {
          if (line.trim().startsWith('version:')) {
            final indent = line.length - line.trimLeft().length;
            return '${" " * indent}version: $newVersion';
          }
          return line;
        }).toList();
        pubspec.writeAsStringSync('${newLines.join('\n')}\n');
        print('Version updated to $newVersion in $path/pubspec.yaml');
        updatedFiles.add(pubspec);
      }
    }
  } else {
    final pubspecFile = File('$projectDir/pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final lines = pubspecFile.readAsLinesSync();
      final newLines = lines.map((line) {
        if (line.trim().startsWith('version:')) {
          final indent = line.length - line.trimLeft().length;
          return '${" " * indent}version: $newVersion';
        }
        return line;
      }).toList();
      pubspecFile.writeAsStringSync('${newLines.join('\n')}\n');
      print('pubspec.yaml updated to version $newVersion.');
      updatedFiles.add(pubspecFile);
    }
  }
  return updatedFiles;
}

String _getReleaseNotes(String projectDir, String version) {
  final file = File('$projectDir/CHANGELOG.md');
  if (!file.existsSync()) return '';
  final content = file.readAsStringSync();
  final lines = content.split('\n');
  final notes = <String>[];
  bool capturing = false;
  for (final line in lines) {
    if (line.startsWith('## ') || line.startsWith('# ')) {
      if (capturing) break; // Reached next version
      if (line.contains(version)) {
        capturing = true;
        continue;
      }
    }
    if (capturing) {
      notes.add(line);
    }
  }
  return notes.join('\n').trim();
}

String _bumpVersion(String current, String type) {
  final clean = current.split('+').first.trim();
  final parts = clean.split('.').map(int.parse).toList();
  if (parts.length < 3) {
    throw FormatException('Invalid version string: $current');
  }

  if (type == 'patch') {
    parts[2]++;
  } else if (type == 'minor') {
    parts[1]++;
    parts[2] = 0;
  } else if (type == 'major') {
    parts[0]++;
    parts[1] = 0;
    parts[2] = 0;
  }

  return parts.join('.');
}
