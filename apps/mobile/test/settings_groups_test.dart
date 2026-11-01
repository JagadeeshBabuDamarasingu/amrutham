import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/backup_recovery_screen.dart';
import 'package:amrutham/ui/settings_screen.dart';

import 'memory_onboarding_store.dart';

Future<void> _show(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [onboardingStoreProvider.overrideWithValue(MemoryOnboardingStore())],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('ago says today, yesterday, days', () {
    final now = DateTime(2026, 11, 10, 9);
    expect(ago(null, now), 'never');
    expect(ago(DateTime(2026, 11, 10, 7), now), 'today');
    expect(ago(DateTime(2026, 11, 9, 23), now), 'yesterday');
    expect(ago(DateTime(2026, 11, 1), now), '9 days ago');
  });

  testWidgets('Settings has four groups and opens Backup and recovery', (tester) async {
    await _show(tester, const SettingsScreen());
    for (final g in ['KEEP YOUR RECORDS SAFE', 'FOR EMERGENCIES', 'ON THIS PHONE', 'HELP']) {
      expect(find.text(g), findsOneWidget);
    }
    expect(find.text('Not backed up yet'), findsOneWidget);
    await tester.tap(find.text('Backup and recovery'));
    await tester.pumpAndSettle();
    expect(find.text('Not backed up yet'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Restore from a backup'), 200);
    expect(find.text('Restore from a backup'), findsOneWidget);
  });
}
