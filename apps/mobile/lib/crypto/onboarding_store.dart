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
}

class SecureStorageOnboardingStore implements OnboardingStore {
  static const _welcomeKey = 'amrutham_welcome_seen';
  static const _recoveryKey = 'amrutham_recovery_record';

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
}
