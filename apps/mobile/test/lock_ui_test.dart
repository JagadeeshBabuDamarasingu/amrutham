// What a person sees: the lock covers the app, the emergency card stays open
// without Print or Share, Back never reaches the screens underneath, and the
// Settings screen and the onboarding question behave.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/lock/app_navigator.dart';
import 'package:amrutham/reminder/alarm_actions.dart';
import 'package:amrutham/lock/ask_lock.dart';
import 'package:amrutham/lock/device_auth.dart';
import 'package:amrutham/lock/lock_controller.dart';
import 'package:amrutham/lock/lock_gate.dart';
import 'package:amrutham/lock/lock_screen.dart' show lockIntroPending;
import 'package:amrutham/lock/lock_settings.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/medication.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/app_lock_screen.dart';

import 'lock_fakes.dart';
import 'memory_onboarding_store.dart';

final _appa = PersonProfile(
  id: const PersonId('appa'),
  displayName: 'Appa',
  relationship: RelationshipType.parent,
  bloodGroup: 'O positive',
  emergencyContacts: const [EmergencyContact(name: 'Anita', phone: '+91 98765 43210', relationship: 'daughter')],
  createdAt: DateTime(2025),
);

List<Override> _overrides(MemoryOnboardingStore store, FakeDeviceAuth auth, {List<PersonProfile>? people}) => [
  onboardingStoreProvider.overrideWithValue(store),
  deviceAuthProvider.overrideWithValue(auth),
  monotonicProvider.overrideWithValue(FakeClock().call),
  profilesProvider.overrideWith((ref) => Stream.value(people ?? [_appa])),
  allergiesProvider.overrideWith((ref, id) => Stream.value(const [])),
  medicationCoursesProvider.overrideWith((ref, id) => Stream.value(const <MedicationCourse>[])),
];

Future<MemoryOnboardingStore> _pumpGated(
  WidgetTester tester, {
  required List<AuthResult> results,
  bool enabled = true,
}) async {
  final store = MemoryOnboardingStore();
  if (enabled) await store.putSetting(LockSettings.storeKey, const LockSettings(enabled: true).encode());
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(store, FakeDeviceAuth(results: results)),
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        builder: (context, child) => LockGate(child: child!),
        home: const Scaffold(body: Center(child: Text('secret records'))),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('with the lock off, the app is just there', (tester) async {
    await _pumpGated(tester, results: [AuthResult.success], enabled: false);
    expect(find.text('secret records'), findsOneWidget);
    expect(find.text('Amrutham is locked'), findsNothing);
  });

  testWidgets('a cold start shows the opening picture for two seconds, then the lock screen', (tester) async {
    lockIntroPending = true;
    final store = MemoryOnboardingStore();
    await store.putSetting(LockSettings.storeKey, const LockSettings(enabled: true).encode());
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(store, FakeDeviceAuth(results: [AuthResult.failed])),
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          builder: (context, child) => LockGate(child: child!),
          home: const Scaffold(body: Text('secret records')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Amrutham'), findsOneWidget);
    expect(find.text('Not unlocked'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Not unlocked'), findsOneWidget);
    expect(lockIntroPending, isFalse);
  });

  testWidgets('a ringing alarm opens its page over the lock screen, with Taken and Snooze', (tester) async {
    await _pumpGated(tester, results: [AuthResult.failed]);
    pendingRing.value = const AlarmRing(AlarmPayload('appa', 'c1', '08:00', 'Metformin', '500 mg'), 1);
    await tester.pumpAndSettle();
    expect(find.text('Time to take'), findsOneWidget);
    expect(find.text('Metformin'), findsOneWidget);
    expect(find.text('Taken'), findsOneWidget);
    expect(find.text('Snooze 10 min'), findsOneWidget);
    expect(pendingRing.value, isNull);
    expect(find.text('secret records'), findsNothing); // the app underneath stays hidden
  });

  testWidgets('with an alarm up at start, the phone prompt does not cover it', (tester) async {
    pendingRing.value = const AlarmRing(AlarmPayload('appa', 'c1', '08:00', 'Metformin', '500 mg'), 1);
    final auth = FakeDeviceAuth(results: [AuthResult.failed]);
    final store = MemoryOnboardingStore();
    await store.putSetting(LockSettings.storeKey, const LockSettings(enabled: true).encode());
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(store, auth),
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          builder: (context, child) => LockGate(child: child!),
          home: const Scaffold(body: Text('secret records')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Time to take'), findsOneWidget);
    expect(auth.calls, 0);
  });

  testWidgets('a refused prompt leaves the records hidden, and Try again opens them', (tester) async {
    await _pumpGated(tester, results: [AuthResult.failed, AuthResult.success]);
    expect(find.text('Not unlocked'), findsOneWidget);
    expect(find.text('secret records'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('secret records'), findsOneWidget);
    expect(find.text('Not unlocked'), findsNothing);
  });

  testWidgets('the app replacing its own screen (the splash) does not remove the lock', (tester) async {
    await _pumpGated(tester, results: [AuthResult.failed]);
    final navigator = appNavigatorKey.currentState!;
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => const Scaffold(body: Text('after splash'))));
    await tester.pumpAndSettle();
    expect(find.text('Not unlocked'), findsOneWidget);
    expect(find.text('after splash'), findsNothing);
  });

  testWidgets('the emergency card opens while locked, without Print or Share, and Back returns to the lock', (tester) async {
    await _pumpGated(tester, results: [AuthResult.failed]);
    // The details are on the lock screen itself, before anything is tapped.
    expect(find.textContaining('+91 98765 43210'), findsOneWidget);
    expect(find.text('ALLERGIES'), findsOneWidget);
    await tester.ensureVisible(find.textContaining('Tap for the full card'));
    await tester.tap(find.textContaining('Tap for the full card'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Only this card is open'), findsOneWidget);
    expect(find.text('Appa'), findsWidgets);
    expect(find.textContaining('+91 98765 43210'), findsOneWidget);
    expect(find.text('Share copy'), findsNothing);
    expect(find.text('Print or save as PDF'), findsNothing);
    expect(find.text('+ Add contact'), findsNothing);
    expect(find.text('secret records'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Not unlocked'), findsOneWidget);
  });

  testWidgets('the system Back button never reaches the screens under the lock', (tester) async {
    await _pumpGated(tester, results: [AuthResult.failed]);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Not unlocked'), findsOneWidget);
    expect(find.text('secret records'), findsNothing);
  });

  testWidgets('unlocking from the locked card opens the app', (tester) async {
    await _pumpGated(tester, results: [AuthResult.failed, AuthResult.success]);
    await tester.ensureVisible(find.textContaining('Tap for the full card'));
    await tester.tap(find.textContaining('Tap for the full card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('secret records'), findsOneWidget);
    expect(find.textContaining('Only this card is open'), findsNothing);
  });

  testWidgets('a widget asking for a card while locked shows it straight away', (tester) async {
    await _pumpGated(tester, results: [AuthResult.failed]);
    final container = ProviderScope.containerOf(tester.element(find.byType(LockGate)));
    container.read(lockProvider.notifier).showCard(const PersonId('appa'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Only this card is open'), findsOneWidget);
  });

  group('Settings', () {
    Future<MemoryOnboardingStore> pumpSettings(WidgetTester tester, FakeDeviceAuth auth, {LockSettings? s}) async {
      final store = MemoryOnboardingStore();
      if (s != null) await store.putSetting(LockSettings.storeKey, s.encode());
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(store, auth),
          child: const MaterialApp(home: AppLockScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return store;
    }

    testWidgets('turning it on proves the phone lock works, then saves', (tester) async {
      tester.view.physicalSize = const Size(400 * 3, 1100 * 3); // tall enough to build the whole list
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final auth = FakeDeviceAuth();
      final store = await pumpSettings(tester, auth);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(auth.calls, 1);
      expect(LockSettings.decode(await store.setting(LockSettings.storeKey)).enabled, isTrue);
      expect(find.text('1 minute'), findsOneWidget);
      expect(find.text('Hide Amrutham in recent apps'), findsOneWidget);
    });

    testWidgets('if the phone does not confirm, nothing is turned on', (tester) async {
      final auth = FakeDeviceAuth(results: [AuthResult.failed]);
      final store = await pumpSettings(tester, auth);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(LockSettings.decode(await store.setting(LockSettings.storeKey)).enabled, isFalse);
      expect(find.textContaining("didn't confirm"), findsOneWidget);
    });

    testWidgets('a phone with no screen lock explains it and cannot turn the lock on', (tester) async {
      final auth = FakeDeviceAuth(available: false);
      await pumpSettings(tester, auth);
      expect(find.text('Your phone has no screen lock'), findsOneWidget);
      expect(find.text('Open phone settings'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch).first).onChanged, isNull);
    });

    testWidgets('the time away can be chosen', (tester) async {
      final store = await pumpSettings(tester, FakeDeviceAuth(), s: const LockSettings(enabled: true));
      await tester.tap(find.text('15 minutes'));
      await tester.pumpAndSettle();
      expect(LockSettings.decode(await store.setting(LockSettings.storeKey)).timeout, LockTimeout.fifteenMinutes);
    });
  });

  group('the question at the end of onboarding', () {
    Future<MemoryOnboardingStore> pumpAsk(WidgetTester tester, FakeDeviceAuth auth, {String? asked}) async {
      final store = MemoryOnboardingStore();
      if (asked != null) await store.putSetting(LockSettings.askedKey, asked);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(store, auth),
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: TextButton(onPressed: () => maybeAskForLock(context, ref), child: const Text('go')),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      return store;
    }

    testWidgets('Turn on confirms with the phone, saves, and is not asked again', (tester) async {
      final auth = FakeDeviceAuth();
      final store = await pumpAsk(tester, auth);
      expect(find.text("Protect Amrutham with your phone's lock?"), findsOneWidget);
      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();
      expect(auth.calls, 1);
      expect(LockSettings.decode(await store.setting(LockSettings.storeKey)).enabled, isTrue);
      expect(await store.setting(LockSettings.askedKey), isNotNull);
    });

    testWidgets('Not now leaves it off and is not asked again', (tester) async {
      final auth = FakeDeviceAuth();
      final store = await pumpAsk(tester, auth);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(auth.calls, 0);
      expect(LockSettings.decode(await store.setting(LockSettings.storeKey)).enabled, isFalse);
      expect(await store.setting(LockSettings.askedKey), isNotNull);
    });

    testWidgets('it is never asked twice', (tester) async {
      await pumpAsk(tester, FakeDeviceAuth(), asked: '1');
      expect(find.text("Protect Amrutham with your phone's lock?"), findsNothing);
    });

    testWidgets('a phone with no screen lock is not asked, and not marked asked', (tester) async {
      final store = await pumpAsk(tester, FakeDeviceAuth(available: false));
      expect(find.text("Protect Amrutham with your phone's lock?"), findsNothing);
      expect(await store.setting(LockSettings.askedKey), isNull);
    });
  });
}
