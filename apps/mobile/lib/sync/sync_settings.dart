import 'dart:convert';

import '../crypto/onboarding_store.dart';

const _keyName = 'sync_key';
const _folderName = 'sync_folder';
const _lastName = 'sync_last';

/// Where this phone stands with family sync. Kept in secure storage, because
/// the family key opens every shard in the shared folder.
class SyncSettings {
  const SyncSettings({this.key, this.folder, this.last});
  final List<int>? key;
  final String? folder;
  final DateTime? last;

  bool get ready => key != null && folder != null;

  static Future<SyncSettings> load(OnboardingStore s) async {
    final k = await s.setting(_keyName);
    final l = await s.setting(_lastName);
    final f = await s.setting(_folderName);
    return SyncSettings(
      key: k == null || k.isEmpty ? null : base64Decode(k),
      folder: f == null || f.isEmpty ? null : f,
      last: l == null || l.isEmpty ? null : DateTime.tryParse(l),
    );
  }

  static Future<void> saveKey(OnboardingStore s, List<int>? key) =>
      s.putSetting(_keyName, key == null ? null : base64Encode(key));
  static Future<void> saveFolder(OnboardingStore s, String? folder) =>
      s.putSetting(_folderName, folder);
  static Future<void> saveLast(OnboardingStore s, DateTime t) =>
      s.putSetting(_lastName, t.toIso8601String());
}

/// The text a family member types or scans to join: "amr1." plus the key.
String familyCode(List<int> key) => 'amr1.${base64Url.encode(key)}';

/// The key inside a code, or null if it isn't one.
List<int>? keyFromFamilyCode(String text) {
  final t = text.trim();
  if (!t.startsWith('amr1.')) return null;
  try {
    final k = base64Url.decode(base64Url.normalize(t.substring(5)));
    return k.length == 32 ? k : null;
  } on FormatException {
    return null;
  }
}
