import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/crypto/recovery_code.dart';
import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/recovery_flow_screen.dart';
import 'package:amrutham/ui/welcome_screen.dart';

import 'memory_onboarding_store.dart';

void main() {
  test('generated codes are 24 unambiguous characters', () {
    final code = RecoveryCode.generate();
    expect(code.value, hasLength(24));
    expect(code.groups, hasLength(6));
    expect(code.value.split('').every(RecoveryCode.alphabet.contains), isTrue);
    expect(RecoveryCode.generate().value, isNot(code.value));
  });

  test('parse accepts typed forms and rejects bad ones', () {
    final code = RecoveryCode.generate();
    expect(
      RecoveryCode.parse(code.formatted.toLowerCase().replaceAll('-', ' '))
          ?.value,
      code.value,
    );
    expect(RecoveryCode.parse('K7QM-2WXD'), isNull);
    expect(RecoveryCode.parse('O' * 24), isNull); // O isn't in the alphabet
  });

  test('a record verifies the code it was made from, and only that', () async {
    final code = RecoveryCode.generate();
    final record = await RecoveryRecord.create(code);
    expect(await record.matches(code), isTrue);
    expect(await record.matches(RecoveryCode.generate()), isFalse);
    // Survives storage.
    final stored = RecoveryRecord.fromJson(record.toJson());
    expect(await stored.matches(code), isTrue);
  });

  testWidgets('flow saves a record only after the code is re-typed', (
    tester,
  ) async {
    final store = MemoryOnboardingStore();
    final code = RecoveryCode.generate();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingStoreProvider.overrideWithValue(store)],
        child: MaterialApp(home: RecoveryFlowScreen(code: code)),
      ),
    );

    expect(find.text('Before we start'), findsOneWidget);
    await tester.tap(find.text('I understand'));
    await tester.pump();

    expect(find.text('Your recovery code'), findsOneWidget);
    expect(find.text(code.groups.first), findsOneWidget);
    await tester.tap(find.text("I've saved it"));
    await tester.pump();

    // Continue stays disabled until both parts match.
    FilledButton continueButton() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'));
    expect(continueButton().onPressed, isNull);

    final fields = find.byType(TextField);
    for (var i = 0; i < 2; i++) {
      final label = tester
          .widget<Text>(find.textContaining('PART ').at(i))
          .data!;
      final part = int.parse(label.substring(5)) - 1;
      await tester.enterText(fields.at(i), code.groups[part].toLowerCase());
    }
    await tester.pump();
    expect(continueButton().onPressed, isNotNull);

    await tester.tap(find.text('Continue'));
    // Argon2id runs on a real isolate, so let real time pass.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 5)));
    await tester.pump();

    final record = store.recovery;
    expect(record, isNotNull);
    expect(await tester.runAsync(() => record!.matches(code)), isTrue);
  });

  testWidgets('welcome screen marks itself seen', (tester) async {
    final store = MemoryOnboardingStore(welcomeSeen: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: WelcomeScreen()),
      ),
    );
    await tester.tap(find.text('Get started'));
    await tester.pump();
    expect(await store.welcomeSeen(), isTrue);
  });
}
