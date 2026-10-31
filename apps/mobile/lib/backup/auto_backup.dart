import 'dart:io';

import 'package:flutter/services.dart';
import 'package:realm/realm.dart';

import '../crypto/onboarding_store.dart';
import '../crypto/recovery_code.dart';
import 'backup_folder.dart';
import 'drive_backup.dart';
import 'vault_backup.dart';

// Settings live in secure storage next to the other small flags.
const _enabledKey = 'auto_enabled';
const _daysKey = 'auto_days';
const _driveKey = 'auto_drive';
const _folderKey = 'auto_folder';
const _secretKey = 'auto_secret';
const _driveErrorKey = 'auto_drive_error';
const _folderErrorKey = 'auto_folder_error';
const folderLastBackupKey = 'folder_last_backup';

/// What the automatic backup screen shows and what a run consults.
class AutoBackupSettings {
  const AutoBackupSettings({
    required this.enabled,
    required this.everyDays,
    required this.drive,
    required this.folder,
    required this.key,
    required this.driveConnected,
    required this.folderChosen,
    this.driveLast,
    this.folderLast,
    this.driveError,
    this.folderError,
  });

  final bool enabled;
  final int everyDays;

  /// The person wants Drive / the folder backed up automatically.
  final bool drive;
  final bool folder;
  final AutoBackupKey? key;

  /// Whether that destination is set up at all.
  final bool driveConnected;
  final bool folderChosen;
  final DateTime? driveLast;
  final DateTime? folderLast;
  final String? driveError;
  final String? folderError;

  static Future<AutoBackupSettings> load(OnboardingStore store) async {
    DateTime? time(String? v) => v == null || v.isEmpty ? null : DateTime.tryParse(v);
    String? text(String? v) => v == null || v.isEmpty ? null : v;
    return AutoBackupSettings(
      enabled: await store.setting(_enabledKey) == '1',
      everyDays: int.tryParse(await store.setting(_daysKey) ?? '') ?? 1,
      drive: await store.setting(_driveKey) == '1',
      folder: await store.setting(_folderKey) == '1',
      key: AutoBackupKey.decode(await store.setting(_secretKey)),
      driveConnected: await store.setting(driveEmailKey) != null,
      folderChosen: await store.backupFolder() != null,
      driveLast: time(await store.setting(driveLastBackupKey)),
      folderLast: time(await store.setting(folderLastBackupKey)),
      driveError: text(await store.setting(_driveErrorKey)),
      folderError: text(await store.setting(_folderErrorKey)),
    );
  }
}

/// Turns automatic backup on. The recovery code must already have been
/// checked: this derives the key from it and keeps only the key.
Future<void> enableAutoBackup(OnboardingStore store, RecoveryCode code) async {
  final key = await VaultBackup.deriveAutoKey(code);
  await store.putSetting(_secretKey, key.encode());
  await store.putSetting(_enabledKey, '1');
  // Start with whatever is already set up.
  await store.putSetting(_driveKey, await store.setting(driveEmailKey) != null ? '1' : '0');
  await store.putSetting(_folderKey, await store.backupFolder() != null ? '1' : '0');
  await store.putSetting(_daysKey, await store.setting(_daysKey) ?? '1');
}

/// Turns it off and forgets the key.
Future<void> disableAutoBackup(OnboardingStore store) async {
  await store.putSetting(_secretKey, null);
  await store.putSetting(_enabledKey, '0');
}

Future<void> setAutoBackupDays(OnboardingStore store, int days) =>
    store.putSetting(_daysKey, '$days');

Future<void> setAutoBackupDestination(OnboardingStore store, {bool? drive, bool? folder}) async {
  if (drive != null) await store.putSetting(_driveKey, drive ? '1' : '0');
  if (folder != null) await store.putSetting(_folderKey, folder ? '1' : '0');
}

/// A little under the interval, so a backup that ran at 09:05 yesterday is due
/// when the check runs at 09:00 today.
bool isDue(DateTime? last, int everyDays, DateTime now) =>
    last == null || now.difference(last) >= Duration(hours: everyDays * 24 - 2);

enum Outcome { skipped, done, failed }

/// Makes the backups that are due: no screen, no recovery code, so it can run
/// from the app or from a background task. [uploadToDrive] and [writeToFolder]
/// are only swapped out in tests.
Future<({Outcome drive, Outcome folder})> runAutoBackup({
  required Realm realm,
  required Directory vault,
  required OnboardingStore store,
  DateTime? now,
  Future<void> Function(List<int> bytes)? uploadToDrive,
  Future<void> Function(String folder, List<int> bytes)? writeToFolder,
}) async {
  const nothing = (drive: Outcome.skipped, folder: Outcome.skipped);
  final s = await AutoBackupSettings.load(store);
  final key = s.key;
  if (!s.enabled || key == null) return nothing;

  final t = now ?? DateTime.now();
  final folderPath = await store.backupFolder();
  final driveDue = s.drive && s.driveConnected && isDue(s.driveLast, s.everyDays, t);
  final folderDue = s.folder && folderPath != null && isDue(s.folderLast, s.everyDays, t);
  if (!driveDue && !folderDue) return nothing;

  final bytes = await VaultBackup.encryptWithKey(await VaultBackup.snapshot(realm, vault), key);

  Future<Outcome> attempt(
    bool due,
    Future<void> Function() write,
    String lastKey,
    String errorKey,
  ) async {
    if (!due) return Outcome.skipped;
    try {
      await write();
      await store.putSetting(lastKey, t.toIso8601String());
      await store.putSetting(errorKey, null);
      return Outcome.done;
    } catch (e) {
      await store.putSetting(errorKey, _short(e));
      return Outcome.failed;
    }
  }

  final drive = await attempt(
    driveDue,
    () => (uploadToDrive ?? DriveSession.instance.upload)(bytes),
    driveLastBackupKey,
    _driveErrorKey,
  );
  final folder = await attempt(
    folderDue,
    () => (writeToFolder ?? (f, b) => writeToBackupFolder(f, backupFileName, b))(folderPath!, bytes),
    folderLastBackupKey,
    _folderErrorKey,
  );
  return (drive: drive, folder: folder);
}

/// A line the screen can show; never the exception's full text.
String _short(Object e) {
  final text = e is PlatformException ? (e.message ?? e.code) : e.toString();
  final line = text.split('\n').first.trim();
  return line.length > 120 ? '${line.substring(0, 117)}…' : line;
}
