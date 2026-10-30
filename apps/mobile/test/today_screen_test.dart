import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/today_screen.dart';

import 'memory_onboarding_store.dart';

/// (given name, relationship, deceased)
typedef _Member = (String, RelationshipType, bool);

/// People are handed straight to the screen: this tests what Today draws, not
/// Realm (whose change notifications are flaky under the test clock).
Future<void> _pumpToday(WidgetTester tester, List<_Member> members) async {
  final people = [
    for (final (i, (given, relationship, deceased)) in members.indexed)
      PersonProfile(
        id: PersonId('p$i'),
        displayName: '$given Reddy',
        givenName: given,
        surname: 'Reddy',
        relationship: relationship,
        createdAt: DateTime(2026),
        isDeceased: deceased,
      ),
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingStoreProvider.overrideWithValue(MemoryOnboardingStore()),
        profilesProvider.overrideWith((ref) => Stream.value(people)),
      ],
      child: const MaterialApp(home: Scaffold(body: TodayScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('greets the person marked as self', (tester) async {
    await _pumpToday(tester, [
      ('Kiran', RelationshipType.parent, false),
      ('Anita', RelationshipType.self, false),
    ]);
    expect(find.textContaining('Anita'), findsOneWidget);
    expect(find.textContaining('Kiran'), findsNothing);
  });

  testWidgets('switching person greets them by given name', (tester) async {
    await _pumpToday(tester, [
      ('Anita', RelationshipType.self, false),
      ('Rohan', RelationshipType.child, false),
    ]);
    await tester.tap(find.text('R')); // Rohan's avatar
    await tester.pumpAndSettle();
    expect(find.textContaining('Rohan'), findsOneWidget);
    expect(find.textContaining('Anita'), findsNothing);
  });

  testWidgets('the numbers card is titled "Today\'s numbers"', (tester) async {
    await _pumpToday(tester, [('Anita', RelationshipType.self, false)]);
    expect(find.text("Today's numbers ›"), findsOneWidget);
    expect(find.text('+ Log'), findsOneWidget);
    expect(find.text('+ Add'), findsNWidgets(3)); // weight, BP, sugar
  });

  testWidgets('a deceased member is not in the switcher or the greeting', (tester) async {
    await _pumpToday(tester, [
      ('Anita', RelationshipType.self, false),
      ('Rohan', RelationshipType.child, false),
      ('Venkata', RelationshipType.parent, true),
    ]);
    expect(find.text('V'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
  });

  testWidgets('only a deceased member left: no switcher, no numbers card', (tester) async {
    await _pumpToday(tester, [('Venkata', RelationshipType.parent, true)]);
    expect(find.text('Start with yourself, or anyone in the family.'), findsOneWidget);
    expect(find.text("Today's numbers ›"), findsNothing);
    expect(find.text('V'), findsNothing);
  });

  testWidgets('past three people the stack shows two and a +N bubble', (tester) async {
    await _pumpToday(tester, [
      ('Anita', RelationshipType.self, false),
      ('Rohan', RelationshipType.child, false),
      ('Meena', RelationshipType.spouse, false),
      ('Kiran', RelationshipType.parent, false),
      ('Sita', RelationshipType.parent, false),
    ]);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('M'), findsNothing); // third person is behind the bubble
    await tester.tap(find.text('+3'));
    await tester.pumpAndSettle();
    expect(find.text('Sita Reddy'), findsOneWidget); // the full list opens
    await tester.tap(find.text('Sita Reddy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sita'), findsOneWidget);
  });

  testWidgets('three people show all three avatars, no bubble', (tester) async {
    await _pumpToday(tester, [
      ('Anita', RelationshipType.self, false),
      ('Rohan', RelationshipType.child, false),
      ('Meena', RelationshipType.spouse, false),
    ]);
    expect(find.text('M'), findsOneWidget);
    expect(find.textContaining('+'), findsNWidgets(4)); // + Log and three + Add; no +N
  });

  testWidgets('the Add sheet fits a phone, even with large text', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpToday(tester, [('Anita', RelationshipType.self, false)]);
    await tester.tap(find.byTooltip('Quick add'));
    await tester.pumpAndSettle();

    expect(find.text('Add a medicine'), findsOneWidget);
    expect(find.text('For Anita. Pick what you want to record.'), findsOneWidget);
    expect(tester.takeException(), isNull); // no RenderFlex overflow
  });
}
