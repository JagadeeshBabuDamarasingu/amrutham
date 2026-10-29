// The splash must not hand over to the first screen until the encrypted
// database has opened — otherwise that screen builds against a closed DB.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm/realm.dart';

import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/splash_screen.dart';

import 'realm_test_helper.dart';

void main() {
  testWidgets('splash waits for the database, then shows the next screen', (
    tester,
  ) async {
    final opening = Completer<Realm>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          databaseProvider.overrideWith((ref) => opening.future),
        ],
        child: const MaterialApp(
          home: SplashScreen(next: Scaffold(body: Text('next screen'))),
        ),
      ),
    );

    // The minimum time has passed (zero) but the database is still opening.
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Opening your vault'), findsOneWidget);
    expect(find.text('next screen'), findsNothing);

    opening.complete(openInMemoryRealm());
    await tester.pumpAndSettle();

    expect(find.text('next screen'), findsOneWidget);
    expect(find.text('Opening your vault'), findsNothing);
  });

  testWidgets('splash offers a retry when the database fails to open', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          databaseProvider.overrideWith(
            (ref) => Future<Realm>.error(StateError('no key')),
          ),
        ],
        child: const MaterialApp(
          home: SplashScreen(next: Scaffold(body: Text('next screen'))),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('next screen'), findsNothing);
  });
}
