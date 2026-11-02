import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/settings_screen.dart';
import 'package:amrutham/ui/settings_search.dart';

import 'memory_onboarding_store.dart';

void main() {
  test('search needs every word, finds titles first, and finds nothing for nonsense', () {
    final lock = searchSettings('lock').map((e) => e.title).toList();
    expect(lock, contains('App lock'));
    expect(lock, contains('Emergency card on the lock screen'));
    expect(searchSettings('recovery code').first.title, contains('recovery code'));
    expect(searchSettings('BACKUP drive'), isNotEmpty);
    expect(searchSettings('xyzzy'), isEmpty);
    expect(searchSettings('   '), isEmpty);
  });

  test('it only ever lists settings and help, not health data', () {
    for (final e in settingsEntries) {
      expect(e.path, startsWith('Settings'));
    }
  });

  testWidgets('typing in Settings shows matches, and clearing brings the groups back', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingStoreProvider.overrideWithValue(MemoryOnboardingStore())],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('KEEP YOUR RECORDS SAFE'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'lock');
    await tester.pumpAndSettle();
    expect(find.text('KEEP YOUR RECORDS SAFE'), findsNothing);
    expect(find.textContaining('RESULT'), findsWidgets);
    expect(find.text('Settings › Keep your records safe'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'xyzzy');
    await tester.pumpAndSettle();
    expect(find.text('NO RESULTS'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('KEEP YOUR RECORDS SAFE'), findsOneWidget);
  });
}
