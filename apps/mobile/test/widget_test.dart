// Boot smoke test. flutter_secure_storage and path_provider both need real
// platform channels, unavailable under `flutter test` — so the database
// provider is overridden with an in-memory DB, bypassing both.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/main.dart';
import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/splash_screen.dart';

import 'memory_onboarding_store.dart';
import 'realm_test_helper.dart';

void main() {
  testWidgets('app boots to an empty Today screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          onboardingStoreProvider.overrideWithValue(MemoryOnboardingStore()),
          databaseProvider.overrideWith((ref) async => openInMemoryRealm()),
        ],
        child: const AmruthamApp(),
      ),
    );

    // The splash hands over once the (instant) DB is ready. Its progress bar
    // animates forever, so pumpAndSettle can't be used until it has gone.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 500));
    // The app gate reads the first-run flag before it builds Home.
    await tester.pump(const Duration(milliseconds: 100));

    // Realm delivers its first query results through a native callback, which
    // the test's fake clock never runs, so let real time pass.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget); // tab bar
    expect(find.text('Start with yourself, or anyone in the family.'), findsOneWidget);
  });
}
