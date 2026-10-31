import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/backup/auto_backup.dart';
import 'package:amrutham/backup/drive_backup.dart';
import 'package:amrutham/crypto/recovery_code.dart';
import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/auto_backup_screen.dart';

import 'memory_onboarding_store.dart';

const _typed = 'ABCD-EFGH-JKMN-PQRS-TUVW-XYZ2';
final _code = RecoveryCode.parse(_typed)!;

/// The screen on its own, over a store that may already have a recovery code.
Future<MemoryOnboardingStore> _pump(
  WidgetTester tester, {
  bool recovery = true,
  Future<void> Function(MemoryOnboardingStore store)? setUp,
}) async {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  final store = MemoryOnboardingStore();
  if (recovery) store.recovery = await tester.runAsync(() => RecoveryRecord.create(_code));
  if (setUp != null) await tester.runAsync(() => setUp(store));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [onboardingStoreProvider.overrideWithValue(store)],
      child: const MaterialApp(home: AutoBackupScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

/// Argon2 runs on real isolates, so wait on the real clock.
Future<void> _until(WidgetTester tester, Future<bool> Function() done) async {
  for (var i = 0; i < 100; i++) {
    if (await tester.runAsync(done) == true) break;
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without a recovery code the switch is off and disabled', (tester) async {
    await _pump(tester, recovery: false);
    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isFalse);
    expect(tile.onChanged, isNull);
    expect(find.textContaining('Make your recovery code first'), findsOneWidget);
    expect(find.text('HOW OFTEN'), findsNothing);
  });

  testWidgets('turning it on asks for the code once and keeps only a key', (tester) async {
    final store = await _pump(tester);
    expect(find.text('HOW OFTEN'), findsNothing);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('Turn on automatic backups'), findsOneWidget);

    await tester.enterText(find.byType(TextField), _typed);
    await tester.tap(find.text('Turn on'));
    await _until(tester, () async => (await AutoBackupSettings.load(store)).enabled);
    await _until(tester, () async => find.text('HOW OFTEN').evaluate().isNotEmpty);

    final s = (await tester.runAsync(() => AutoBackupSettings.load(store)))!;
    expect(s.enabled, isTrue);
    expect(s.key, isNotNull);
    expect(s.everyDays, 1);
    expect(find.text('HOW OFTEN'), findsOneWidget);
    // The code itself was never written anywhere.
    final stored = (await tester.runAsync(() async => [
      for (final k in ['auto_secret', 'auto_enabled', 'auto_days']) await store.setting(k),
    ]))!;
    expect(stored.whereType<String>().any((v) => v.contains(_typed)), isFalse);
  });

  testWidgets('a wrong code does not turn it on', (tester) async {
    final store = await _pump(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZ');
    await tester.tap(find.text('Turn on'));
    await _until(tester, () async => find.text('That does not match your recovery code.').evaluate().isNotEmpty);

    expect(find.text('That does not match your recovery code.'), findsOneWidget);
    expect((await tester.runAsync(() => AutoBackupSettings.load(store)))!.enabled, isFalse);
  });

  testWidgets('destinations that are not set up are disabled with a hint', (tester) async {
    await _pump(tester, setUp: (store) => enableAutoBackup(store, _code));
    expect(find.text('Connect Google Drive in "Where backups go" first.'), findsOneWidget);
    expect(find.text('Choose a folder in "Where backups go" first.'), findsOneWidget);
    for (final tile in tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).skip(1)) {
      expect(tile.onChanged, isNull);
    }
  });

  testWidgets('connected destinations can be switched, and the interval changed', (tester) async {
    final store = await _pump(tester, setUp: (store) async {
      await store.putSetting(driveEmailKey, 'me@example.com');
      await store.setBackupFolder('content://tree/x');
      await enableAutoBackup(store, _code);
    });
    expect(find.textContaining('me@example.com'), findsOneWidget);

    await tester.tap(find.text('Every week'));
    await tester.pumpAndSettle();
    expect((await tester.runAsync(() => AutoBackupSettings.load(store)))!.everyDays, 7);

    await tester.tap(find.text('Google Drive'));
    await tester.pumpAndSettle();
    expect((await tester.runAsync(() => AutoBackupSettings.load(store)))!.drive, isFalse);
  });

  testWidgets('it shows the last backup and a failed attempt', (tester) async {
    await _pump(tester, setUp: (store) async {
      await store.putSetting(driveEmailKey, 'me@example.com');
      await enableAutoBackup(store, _code);
      await store.putSetting(driveLastBackupKey, DateTime(2026, 10, 30, 20, 33).toIso8601String());
      await store.putSetting('auto_drive_error', 'No activity');
    });
    expect(find.textContaining('Last backup:'), findsOneWidget);
    expect(find.textContaining("Couldn't back up: No activity"), findsOneWidget);
  });

  testWidgets('turning it off deletes the key', (tester) async {
    final store = await _pump(tester, setUp: (store) => enableAutoBackup(store, _code));
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();

    final s = (await tester.runAsync(() => AutoBackupSettings.load(store)))!;
    expect((s.enabled, s.key), (false, null));
    expect(find.text('HOW OFTEN'), findsNothing);
  });
}
