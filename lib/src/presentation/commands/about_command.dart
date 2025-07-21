import 'dart:io';
import 'package:shepherd/src/utils/ansi_colors.dart';

Future<void> runAboutCommand(List<String> args) async {
  final pubspec = File('pubspec.yaml');
  if (!await pubspec.exists()) {
    print('pubspec.yaml not found');
    return;
  }
  final lines = await pubspec.readAsLines();
  String name = '',
      version = '',
      description = '',
      homepage = '',
      repository = '',
      documentation = '',
      license = '';
  for (final line in lines) {
    if (line.trim().startsWith('name:')) name = line.split(':').last.trim();
    if (line.trim().startsWith('version:')) {
      version = line.split(':').last.trim();
    }
    if (line.trim().startsWith('description:')) {
      description = line.split(':').last.trim();
    }
    if (line.trim().startsWith('homepage:')) {
      homepage = line.split(':').last.trim();
      if (homepage.startsWith('//')) homepage = homepage.substring(2);
    }
    if (line.trim().startsWith('repository:')) {
      repository = line.split(':').last.trim();
      if (repository.startsWith('//')) repository = repository.substring(2);
    }
    if (line.trim().startsWith('documentation:')) {
      documentation = line.split(':').last.trim();
      if (documentation.startsWith('//')) {
        documentation = documentation.substring(2);
      }
    }
    if (line.trim().startsWith('license:')) {
      license = line.split(':').last.trim();
    }
  }

  String normalizeUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }

  // Helper to create clickable links in supported terminals (OSC 8)
  String clickable(String text, String url) {
    if (url.isEmpty) return '';
    return '\x1b]8;;$url\x07$text\x1b]8;;\x07';
  }

  final homepageUrl = normalizeUrl(homepage);
  final repositoryUrl = normalizeUrl(repository);
  final docsUrl = normalizeUrl(documentation);

  final homepageLink =
      homepage.isNotEmpty ? clickable(homepage, homepageUrl) : '';
  final repositoryLink =
      repository.isNotEmpty ? clickable(repository, repositoryUrl) : '';
  final docsLink =
      documentation.isNotEmpty ? clickable(documentation, docsUrl) : '';

  // Use centralized ANSI color constants

  final border =
      '${AnsiColors.cyan}===============================================${AnsiColors.reset}';
  final title =
      '${AnsiColors.bold}${AnsiColors.yellow}Shepherd CLI - About${AnsiColors.reset}';

  print('''
$border
$title
$border
${AnsiColors.bold}Name:       ${AnsiColors.reset}$name
${AnsiColors.bold}Version:    ${AnsiColors.reset}$version
${AnsiColors.bold}Description:${AnsiColors.reset} $description
${AnsiColors.bold}Author:     ${AnsiColors.reset} Vinicius Cruvinel <viniciusmcruvinel@gmail.com>
${AnsiColors.bold}Homepage:   ${AnsiColors.reset}${homepageLink.isNotEmpty ? homepageLink : homepage}
${AnsiColors.bold}Repository: ${AnsiColors.reset}${repositoryLink.isNotEmpty ? repositoryLink : repository}
${AnsiColors.bold}Docs:       ${AnsiColors.reset}${docsLink.isNotEmpty ? docsLink : documentation}
${AnsiColors.bold}License:    ${AnsiColors.reset}${license.isNotEmpty ? license : 'Not specified'}
$border
''');
}
