// The app lock must never trap anyone: it locks when asked, relocks only after
// the chosen time away, and opens whenever the phone has nothing to ask with.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/crypto/onboarding_store.dart';
import 'package:amrutham/lock/device_auth.dart';
import 'package:amrutham/lock/lock_controller.dart';
import 'package:amrutham/lock/lock_settings.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/providers/app_providers.dart';

import 'lock_fakes.dart';
import 'memory_onboarding_store.dart';

Future<({ProviderContainer c, FakeDeviceAuth auth, FakeClock clock, OnboardingStore store})> _make({
  LockSettings? settings,
  List<AuthResult>? results,
  bool available = true,
}) async {
  final store = MemoryOnboardingStore();
  if (settings != null) await store.putSetting(LockSettings.storeKey, settings.encode());
  final auth = FakeDeviceAuth(available: available, results: results);
  final clock = FakeClock();
  final c = ProviderContainer(
    overrides: [
      onboardingStoreProvider.overrideWithValue(store),
      deviceAuthProvider.overrideWithValue(auth),
      monotonicProvider.overrideWithValue(clock.call),
    ],
  );
  addTearDown(c.dispose);
  c.listen(lockProvider, (_, _) {}); // keep the notifier alive
  return (c: c, auth: auth, clock: clock, store: store);
}

const _on = LockSettings(enabled: true);

void main() {
  group('LockSettings', () {
    test('start off, one minute, hiding the app in recents', () {
      const s = LockSettings();
      expect((s.enabled, s.timeout, s.hideInRecents), (false, LockTimeout.oneMinute, true));
    });

    test('round-trip, and damaged storage means off', () {
      final s = const LockSettings().copyWith(enabled: true, timeout: LockTimeout.fiveMinutes, hideInRecents: false);
      final back = LockSettings.decode(s.encode());
      expect((back.enabled, back.timeout, back.hideInRecents), (true, LockTimeout.fiveMinutes, false));
      expect(LockSettings.decode(null).enabled, isFalse);
      expect(LockSettings.decode('{nope').enabled, isFalse);
      expect(LockSettings.decode('{"enabled":true,"timeout":"someday"}').timeout, LockTimeout.oneMinute);
    });
  });

  group('start-up', () {
    test('with the lock off, the app is open and nothing is asked', () async {
      final t = await _make();
      expect(t.c.read(lockProvider).checking, isTrue);
      await t.c.read(lockProvider.notifier).start();
      final s = t.c.read(lockProvider);
      expect((s.checking, s.locked), (false, false));
      expect(t.auth.calls, 0);
    });

    test('with the lock on, it is locked and asks once, then opens', () async {
      final t = await _make(settings: _on);
      await t.c.read(lockProvider.notifier).start();
      expect(t.auth.calls, 1);
      expect(t.c.read(lockProvider).locked, isFalse);
    });

    test('a failed prompt stays locked and says so; trying again can open it', () async {
      final t = await _make(settings: _on, results: [AuthResult.failed, AuthResult.success]);
      final lock = t.c.read(lockProvider.notifier);
      await lock.start();
      expect((t.c.read(lockProvider).locked, t.c.read(lockProvider).failed), (true, true));
      await lock.unlock();
      expect((t.c.read(lockProvider).locked, t.c.read(lockProvider).failed), (false, false));
    });

    test('a phone with no screen lock opens the app instead of trapping it', () async {
      final t = await _make(settings: _on, results: [AuthResult.unavailable]);
      await t.c.read(lockProvider.notifier).start();
      final s = t.c.read(lockProvider);
      expect((s.locked, s.unavailable), (false, true));
    });

    test('whenReady completes even when the settings are off', () async {
      final t = await _make();
      final lock = t.c.read(lockProvider.notifier);
      lock.start();
      await lock.whenReady;
      expect(t.c.read(lockProvider).checking, isFalse);
    });
  });

  group('coming back to the app', () {
    Future<LockController> opened(({ProviderContainer c, FakeDeviceAuth auth, FakeClock clock, OnboardingStore store}) t) async {
      final lock = t.c.read(lockProvider.notifier);
      await lock.start();
      t.clock.advance(const Duration(minutes: 10)); // well clear of the grace period
      return lock;
    }

    test('dismissing the prompt does not bring it straight back', () async {
      final t = await _make(settings: _on, results: [AuthResult.failed]);
      final lock = t.c.read(lockProvider.notifier);
      await lock.start();
      expect(t.auth.calls, 1);
      await lock.returnedToApp(); // the app resumes when the prompt closes
      expect(t.auth.calls, 1);
      expect(t.c.read(lockProvider).locked, isTrue);
    });

    test('back within the chosen time stays open', () async {
      final t = await _make(settings: _on);
      final lock = await opened(t);
      lock.leftApp();
      t.clock.advance(const Duration(seconds: 59));
      await lock.returnedToApp();
      expect(t.c.read(lockProvider).locked, isFalse);
      expect(t.auth.calls, 1);
    });

    test('back after the chosen time locks and asks again', () async {
      final t = await _make(settings: _on);
      final lock = await opened(t);
      lock.leftApp();
      t.clock.advance(const Duration(minutes: 1));
      await lock.returnedToApp();
      expect(t.auth.calls, 2);
      expect(t.c.read(lockProvider).locked, isFalse); // the fake says yes
    });

    test('if that prompt is refused it stays locked', () async {
      final t = await _make(settings: _on, results: [AuthResult.success, AuthResult.failed]);
      final lock = await opened(t);
      lock.leftApp();
      t.clock.advance(const Duration(minutes: 2));
      await lock.returnedToApp();
      expect((t.c.read(lockProvider).locked, t.c.read(lockProvider).failed), (true, true));
    });

    test('"right away" locks on every return', () async {
      final t = await _make(settings: _on.copyWith(timeout: LockTimeout.immediately));
      final lock = await opened(t);
      lock.leftApp();
      await lock.returnedToApp();
      expect(t.auth.calls, 2);
    });

    test('a return that follows an unlock by a moment is not a second lock', () async {
      final t = await _make(settings: _on.copyWith(timeout: LockTimeout.immediately));
      final lock = t.c.read(lockProvider.notifier);
      await lock.start(); // unlocks at time zero
      lock.leftApp();
      t.clock.advance(const Duration(seconds: 1));
      await lock.returnedToApp(); // the credential screen resuming the app
      expect(t.auth.calls, 1);
    });

    test('the lock being switched off releases a locked app', () async {
      final t = await _make(settings: _on, results: [AuthResult.failed]);
      final lock = t.c.read(lockProvider.notifier);
      await lock.start();
      expect(t.c.read(lockProvider).locked, isTrue);
      await t.store.putSetting(LockSettings.storeKey, const LockSettings().encode());
      t.c.invalidate(lockSettingsProvider);
      await lock.settingsChanged();
      expect(t.c.read(lockProvider).locked, isFalse);
    });
  });

  group('shortcuts and widgets', () {
    test('ensureUnlocked is true at once when open, and asks when locked', () async {
      final t = await _make(settings: _on, results: [AuthResult.failed, AuthResult.success]);
      final lock = t.c.read(lockProvider.notifier);
      await lock.start(); // refused
      expect(await lock.ensureUnlocked(), isTrue); // second answer: success
      expect(t.auth.calls, 2);
      expect(await lock.ensureUnlocked(), isTrue);
      expect(t.auth.calls, 2); // already open: no prompt
    });

    test('ensureUnlocked is false if the person does not unlock', () async {
      final t = await _make(settings: _on, results: [AuthResult.failed]);
      final lock = t.c.read(lockProvider.notifier);
      await lock.start();
      expect(await lock.ensureUnlocked(), isFalse);
    });

    test('an emergency card can be requested while locked, then taken once', () async {
      final t = await _make(settings: _on, results: [AuthResult.failed]);
      final lock = t.c.read(lockProvider.notifier);
      await lock.start();
      lock.showCard(const PersonId('appa'));
      expect(t.c.read(lockProvider).cardFor, const PersonId('appa'));
      lock.cardShown();
      expect(t.c.read(lockProvider).cardFor, isNull);
    });
  });
}
