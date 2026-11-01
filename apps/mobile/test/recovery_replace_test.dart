import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/backup/auto_backup.dart';
import 'package:amrutham/crypto/recovery_code.dart';
import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/recovery_cases_screen.dart';
import 'package:amrutham/ui/recovery_flow_screen.dart';

import 'memory_onboarding_store.dart';

void main() {
  testWidgets('every case says what comes back, and the worst ones say it cannot', (tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RecoveryCasesScreen())));
    expect(find.text('Getting your records back'), findsOneWidget);
    expect(find.text('Make a new code'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cannot be restored'), 300);
    expect(find.text('Cannot be restored'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Backup stays locked'), 300);
    expect(find.text('Backup stays locked'), findsOneWidget);
  });

  testWidgets('a new code also becomes the key for automatic backups', (tester) async {
    final store = MemoryOnboardingStore();
    final old = RecoveryCode.generate();
    store.recovery = await tester.runAsync(() => RecoveryRecord.create(old));
    await tester.runAsync(() => enableAutoBackup(store, old));
    final before = (await tester.runAsync(() => AutoBackupSettings.load(store)))!.key!.encode();

    final code = RecoveryCode.generate();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingStoreProvider.overrideWithValue(store)],
        child: MaterialApp(home: RecoveryFlowScreen(code: code)),
      ),
    );
    await tester.tap(find.text('I understand'));
    await tester.pump();
    await tester.tap(find.text("I've saved it"));
    await tester.pump();
    for (var i = 0; i < 2; i++) {
      final part = int.parse(tester.widget<Text>(find.textContaining('PART ').at(i)).data!.substring(5)) - 1;
      await tester.enterText(find.byType(TextField).at(i), code.groups[part]);
    }
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 6)));
    await tester.pump();

    expect(await tester.runAsync(() => store.readRecovery().then((r) => r!.matches(code))), isTrue);
    final after = (await tester.runAsync(() => AutoBackupSettings.load(store)))!;
    expect(after.enabled, isTrue);
    expect(after.key!.encode(), isNot(before));
  });
}
