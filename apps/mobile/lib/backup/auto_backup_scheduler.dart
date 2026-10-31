import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../crypto/key_manager.dart';
import '../crypto/onboarding_store.dart';
import '../db/connection.dart';
import 'auto_backup.dart';

const _uniqueName = 'amrutham-auto-backup';
const _taskName = 'autoBackup';

/// What Android runs, with the app closed, for each scheduled check. It makes
/// whichever backups are due; failures are recorded for the settings screen
/// and retried at the next check, so the task itself always reports success.
@pragma('vm:entry-point')
void autoBackupDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    final realm = await openRealm(await const SecureStorageDbKeyProvider().getOrCreateDbKey());
    try {
      final docs = await getApplicationDocumentsDirectory();
      await runAutoBackup(
        realm: realm,
        vault: Directory(p.join(docs.path, 'vault')),
        store: const SecureStorageOnboardingStore(),
      );
    } finally {
      realm.close();
    }
    return true;
  });
}

/// Keeps Android's schedule in step with the settings. Android-only: other
/// platforms just back up when the app opens.
class AutoBackupScheduler {
  static Future<void> init() async {
    if (Platform.isAndroid) await Workmanager().initialize(autoBackupDispatcher);
  }

  static Future<void> sync(OnboardingStore store) async {
    if (!Platform.isAndroid) return;
    final s = await AutoBackupSettings.load(store);
    final driveOn = s.drive && s.driveConnected;
    final folderOn = s.folder && s.folderChosen;
    final workmanager = Workmanager();
    if (!s.enabled || s.key == null || !(driveOn || folderOn)) {
      await workmanager.cancelByUniqueName(_uniqueName);
      return;
    }
    // Checked twice a day; what is actually due follows the daily or weekly
    // choice. Android picks the exact moment.
    await workmanager.registerPeriodicTask(
      _uniqueName,
      _taskName,
      frequency: const Duration(hours: 12),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
        networkType: driveOn ? NetworkType.connected : NetworkType.notRequired,
        requiresBatteryNotLow: true,
      ),
    );
  }
}
