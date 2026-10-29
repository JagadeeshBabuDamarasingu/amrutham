import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'recovery_code.dart';

/// Small first-run state, kept beside the device DB key in secure storage so
/// there is one place that survives app restarts.
abstract class OnboardingStore {
  Future<bool> welcomeSeen();
  Future<void> markWelcomeSeen();

  /// Null until the user has saved and confirmed a recovery code.
  Future<RecoveryRecord?> readRecovery();
  Future<void> saveRecovery(RecoveryRecord record);

  /// The daily tip above the tab bar; on unless the user hides it.
  Future<bool> tipsHidden();
  Future<void> setTipsHidden(bool hidden);

  /// Folder that "Back up now" writes into, or null to use the share sheet.
  Future<String?> backupFolder();
  Future<void> setBackupFolder(String? path);

  /// App language code, e.g. 'hi'; null means English.
  Future<String?> language();
  Future<void> setLanguage(String code);
}

class SecureStorageOnboardingStore implements OnboardingStore {
  static const _welcomeKey = 'amrutham_welcome_seen';
  static const _recoveryKey = 'amrutham_recovery_record';
  static const _tipsHiddenKey = 'amrutham_tips_hidden';
  static const _languageKey = 'amrutham_language';
  static const _backupFolderKey = 'amrutham_backup_folder';

  final FlutterSecureStorage _storage;

  const SecureStorageOnboardingStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<bool> welcomeSeen() async =>
      await _storage.read(key: _welcomeKey) != null;

  @override
  Future<void> markWelcomeSeen() =>
      _storage.write(key: _welcomeKey, value: '1');

  @override
  Future<RecoveryRecord?> readRecovery() async {
    final raw = await _storage.read(key: _recoveryKey);
    if (raw == null) return null;
    return RecoveryRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveRecovery(RecoveryRecord record) =>
      _storage.write(key: _recoveryKey, value: jsonEncode(record.toJson()));

  @override
  Future<bool> tipsHidden() async =>
      await _storage.read(key: _tipsHiddenKey) != null;

  @override
  Future<void> setTipsHidden(bool hidden) => hidden
      ? _storage.write(key: _tipsHiddenKey, value: '1')
      : _storage.delete(key: _tipsHiddenKey);

  @override
  Future<String?> backupFolder() => _storage.read(key: _backupFolderKey);

  @override
  Future<void> setBackupFolder(String? path) => path == null
      ? _storage.delete(key: _backupFolderKey)
      : _storage.write(key: _backupFolderKey, value: path);

  @override
  Future<String?> language() => _storage.read(key: _languageKey);

  @override
  Future<void> setLanguage(String code) =>
      _storage.write(key: _languageKey, value: code);
}
