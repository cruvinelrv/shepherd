import 'dart:convert';
import 'dart:typed_data';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

/// `major.minor.patch`.
class EngineVersion implements Comparable<EngineVersion> {
  final int major, minor, patch;
  const EngineVersion(this.major, this.minor, this.patch);

  /// Reads `1.2.3` or `v1.2.3`; null if it is not a version.
  static EngineVersion? tryParse(String text) {
    final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(text.trim());
    if (m == null) return null;
    return EngineVersion(
        int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  }

  @override
  int compareTo(EngineVersion o) {
    for (final pair in [
      [major, o.major],
      [minor, o.minor],
      [patch, o.patch],
    ]) {
      if (pair[0] != pair[1]) return pair[0].compareTo(pair[1]);
    }
    return 0;
  }

  bool operator >(EngineVersion o) => compareTo(o) > 0;

  @override
  bool operator ==(Object other) =>
      other is EngineVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// One downloadable package for one platform.
class EnginePackage {
  final String url;
  final String sha256;
  final int size;
  const EnginePackage(
      {required this.url, required this.sha256, required this.size});
}

/// What the feed (`latest.json`) says about the newest engine.
class EngineManifest {
  final EngineVersion version;
  final EngineVersion? minimumVersion;
  final String notes;
  final Map<String, EnginePackage> packages;

  const EngineManifest({
    required this.version,
    required this.notes,
    required this.packages,
    this.minimumVersion,
  });

  /// Throws [FormatException] for anything that is not a valid feed.
  factory EngineManifest.parse(String source) {
    final Object? raw;
    try {
      raw = jsonDecode(source);
    } on FormatException {
      throw const FormatException('the feed is not JSON');
    }
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('the feed is not an object');
    }
    final version = EngineVersion.tryParse('${raw['version']}');
    if (version == null) {
      throw const FormatException('the feed has no valid version');
    }
    final packages = <String, EnginePackage>{};
    final platforms = raw['platforms'];
    if (platforms is Map) {
      platforms.forEach((key, value) {
        if (value is! Map) return;
        final url = '${value['url'] ?? ''}';
        final sha = '${value['sha256'] ?? ''}'.toLowerCase();
        // Only https, and only a real hash: anything else is ignored.
        if (url.startsWith('https://') &&
            RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) {
          packages['$key'] = EnginePackage(
              url: url,
              sha256: sha,
              size: (value['size'] as num?)?.toInt() ?? 0);
        }
      });
    }
    return EngineManifest(
      version: version,
      minimumVersion: EngineVersion.tryParse('${raw['minimum_version'] ?? ''}'),
      notes: '${raw['notes'] ?? ''}',
      packages: packages,
    );
  }
}

/// Checks that the feed was signed by Shepherd. Without it, a compromised
/// download host could make every installed CLI run its code.
class EngineSignature {
  EngineSignature._();

  /// [publicKeyBase64] is the 32-byte Ed25519 public key; [signatureBase64] the
  /// 64-byte signature of exactly [message]. False for anything malformed.
  static bool verify({
    required List<int> message,
    required String signatureBase64,
    required String publicKeyBase64,
  }) {
    try {
      final key = base64.decode(publicKeyBase64.trim());
      final sig = base64.decode(signatureBase64.trim());
      if (key.length != 32 || sig.length != 64) return false;
      return ed.verify(ed.PublicKey(Uint8List.fromList(key)),
          Uint8List.fromList(message), Uint8List.fromList(sig));
    } catch (_) {
      return false;
    }
  }
}
