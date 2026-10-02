import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/datasources/pub_dev_datasource.dart';
import '../entities/update_entities.dart' as entities;
import 'install_method_detector.dart';

/// Looks up the newest published version. A pub.dev install follows pub.dev; the
/// others (Homebrew, install script) follow the GitHub release, which is where
/// their binaries come from.
class LatestVersionService {
  static const releaseUrl = 'https://github.com/cruvinelrv/shepherd/releases';
  static const _latestApi =
      'https://api.github.com/repos/cruvinelrv/shepherd/releases/latest';

  final http.Client _client;
  final PubDevDatasource _pub;

  LatestVersionService({http.Client? client, PubDevDatasource? pub})
      : _client = client ?? http.Client(),
        _pub = pub ?? PubDevDatasource(client: client);

  /// Null when it cannot be determined (offline, rate limited, unexpected reply).
  Future<String?> latestFor(InstallMethod method) async {
    if (method == InstallMethod.pubGlobal) {
      return _pub.getLatestVersion('shepherd');
    }
    try {
      final res = await _client.get(Uri.parse(_latestApi), headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'shepherd-cli',
      }).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final tag = (jsonDecode(res.body) as Map)['tag_name'];
      return tag is String ? tag.replaceFirst(RegExp(r'^v'), '') : null;
    } catch (_) {
      return null;
    }
  }

  /// See [compareVersions].
  static int compareVersions(String a, String b) => entities.compareVersions(a, b);
}
