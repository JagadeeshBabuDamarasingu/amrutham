import 'package:amrutham/crypto/onboarding_store.dart';
import 'package:amrutham/crypto/recovery_code.dart';

/// In-memory stand-in: flutter_secure_storage needs real platform channels.
class MemoryOnboardingStore implements OnboardingStore {
  MemoryOnboardingStore({bool welcomeSeen = true, this.recovery})
    : _welcomeSeen = welcomeSeen;

  bool _welcomeSeen;
  bool _tipsHidden = false;
  RecoveryRecord? recovery;

  @override
  Future<bool> welcomeSeen() async => _welcomeSeen;

  @override
  Future<void> markWelcomeSeen() async => _welcomeSeen = true;

  @override
  Future<RecoveryRecord?> readRecovery() async => recovery;

  @override
  Future<void> saveRecovery(RecoveryRecord record) async => recovery = record;

  @override
  Future<bool> tipsHidden() async => _tipsHidden;

  @override
  Future<void> setTipsHidden(bool hidden) async => _tipsHidden = hidden;

  String? _backupFolder;

  @override
  Future<String?> backupFolder() async => _backupFolder;

  @override
  Future<void> setBackupFolder(String? path) async => _backupFolder = path;

  String? _language;

  @override
  Future<String?> language() async => _language;

  @override
  Future<void> setLanguage(String code) async => _language = code;

  final _settings = <String, String>{};

  @override
  Future<String?> setting(String key) async => _settings[key];

  @override
  Future<void> putSetting(String key, String? value) async =>
      value == null ? _settings.remove(key) : _settings[key] = value;
}
