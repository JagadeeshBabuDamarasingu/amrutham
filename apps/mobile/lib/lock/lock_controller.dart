import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'device_auth.dart';
import 'lock_settings.dart';

final deviceAuthProvider = Provider<DeviceAuth>((ref) => LocalDeviceAuth());

/// A clock that only goes forward, so changing the phone's date can't unlock
/// (or lock) the app. Replaced in tests.
final monotonicProvider = Provider<Duration Function()>((ref) {
  final watch = Stopwatch()..start();
  return () => watch.elapsed;
});

final lockSettingsProvider = FutureProvider<LockSettings>((ref) async {
  return LockSettings.decode(
    await ref.watch(onboardingStoreProvider).setting(LockSettings.storeKey),
  );
});

/// Writes the settings and refreshes what depends on them.
Future<void> saveLockSettings(WidgetRef ref, LockSettings settings) async {
  await ref.read(onboardingStoreProvider).putSetting(LockSettings.storeKey, settings.encode());
  ref.invalidate(lockSettingsProvider);
}

class AppLockState {
  const AppLockState({
    this.checking = true,
    this.locked = false,
    this.failed = false,
    this.unavailable = false,
    this.cardFor,
  });

  /// True until the settings have been read at start-up: the app stays covered
  /// so nothing shows for a moment before the lock appears.
  final bool checking;
  final bool locked;

  /// The last attempt did not unlock.
  final bool failed;

  /// The phone has no screen lock, so the lock stayed open instead of trapping
  /// the person. Settings explains it.
  final bool unavailable;

  /// A widget or shortcut asked for this person's emergency card while locked.
  final PersonId? cardFor;

  AppLockState copyWith({
    bool? checking,
    bool? locked,
    bool? failed,
    bool? unavailable,
    PersonId? cardFor,
    bool clearCard = false,
  }) => AppLockState(
    checking: checking ?? this.checking,
    locked: locked ?? this.locked,
    failed: failed ?? this.failed,
    unavailable: unavailable ?? this.unavailable,
    cardFor: clearCard ? null : (cardFor ?? this.cardFor),
  );
}

final lockProvider = NotifierProvider<LockController, AppLockState>(LockController.new);

class LockController extends Notifier<AppLockState> {
  Duration? _leftAt;
  Duration? _unlockedAt;
  Future<void>? _attempt;
  bool get _prompting => _attempt != null;
  bool _started = false;
  final _ready = Completer<void>();

  /// Ignore app-switch noise this soon after an unlock: some phones pause and
  /// resume the app around the credential screen, which must not relock it.
  static const _grace = Duration(seconds: 3);

  @override
  AppLockState build() => const AppLockState();

  /// Completes once start-up has decided whether the app is locked.
  Future<void> get whenReady => _ready.future;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final settings = await ref.read(lockSettingsProvider.future);
      state = state.copyWith(checking: false, locked: settings.enabled);
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
    if (state.locked) await unlock();
  }

  /// Asks the phone to unlock. A second call while a prompt is already open
  /// waits for that prompt instead of being ignored, so a shortcut that arrives
  /// during the start-up prompt still gets its answer.
  Future<void> unlock() {
    if (!state.locked && _attempt == null) return Future.value();
    return _attempt ??= _askPhone().whenComplete(() => _attempt = null);
  }

  Future<void> _askPhone() async {
    final result = await ref.read(deviceAuthProvider).authenticate('Open Amrutham');
    switch (result) {
      case AuthResult.success:
        _unlockedAt = ref.read(monotonicProvider)();
        _leftAt = null;
        state = state.copyWith(locked: false, failed: false);
      case AuthResult.unavailable:
        state = state.copyWith(locked: false, failed: false, unavailable: true);
      case AuthResult.failed:
        state = state.copyWith(failed: true);
    }
  }

  /// For a shortcut or widget that needs the real app. False if it stayed locked.
  Future<bool> ensureUnlocked() async {
    await whenReady;
    if (!state.locked) return true;
    await unlock();
    return !state.locked;
  }

  /// The app went out of sight (only a full pause counts; the system's own
  /// prompt over the app does not).
  void leftApp() {
    if (_prompting) return;
    _leftAt = ref.read(monotonicProvider)();
  }

  Future<void> returnedToApp() async {
    final left = _leftAt;
    _leftAt = null;
    if (_prompting) return;
    final settings = await ref.read(lockSettingsProvider.future);
    if (!settings.enabled) {
      if (state.locked) state = state.copyWith(locked: false, failed: false);
      return;
    }
    if (state.locked) {
      // Only ask again if the app really went away. Dismissing the prompt also
      // resumes the app, and asking then would trap the person in a loop.
      if (left != null) await unlock();
      return;
    }
    final now = ref.read(monotonicProvider)();
    final unlockedAt = _unlockedAt;
    if (unlockedAt != null && now - unlockedAt < _grace) return;
    if (left == null) return;
    if (now - left >= settings.timeout.after) {
      state = state.copyWith(locked: true, failed: false);
      await unlock();
    }
  }

  /// The lock was switched off in Settings while locked, or the settings
  /// changed: re-read and release if it is no longer wanted.
  Future<void> settingsChanged() async {
    final settings = await ref.read(lockSettingsProvider.future);
    if (!settings.enabled && state.locked) state = state.copyWith(locked: false, failed: false);
    if (!settings.enabled) state = state.copyWith(unavailable: false);
  }

  void showCard(PersonId id) => state = state.copyWith(cardFor: id);

  void cardShown() => state = state.copyWith(clearCard: true);
}
