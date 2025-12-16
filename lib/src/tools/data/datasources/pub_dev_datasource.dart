import 'dart:convert';
import 'package:http/http.dart' as http;

/// Datasource for fetching package information from pub.dev
class PubDevDatasource {
  static const String _baseUrl = 'https://pub.dev/api/packages';

  final http.Client _client;

  PubDevDatasource({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches the latest version of a package from pub.dev
  /// Returns null if the package is not found or an error occurs
  Future<String?> getLatestVersion(String packageName) async {
    try {
      final uri = Uri.parse('$_baseUrl/$packageName');
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final latest = data['latest'] as Map<String, dynamic>?;
        return latest?['version'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      // Silent fail - update check is not critical
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
