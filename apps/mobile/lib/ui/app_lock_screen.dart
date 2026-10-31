import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lock/device_auth.dart';
import '../lock/lock_controller.dart';
import '../lock/lock_settings.dart';
import '../lock/secure_screen.dart';
import 'app_style.dart';

/// Whether the phone has a screen lock to borrow. Read when the screen opens.
final lockAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.read(deviceAuthProvider).isAvailable(),
);

/// Settings > App lock (frames 14d and 14e).
class AppLockScreen extends ConsumerWidget {
  const AppLockScreen({super.key});

  Future<void> _turnOn(BuildContext context, WidgetRef ref, LockSettings s) async {
    // Prove the phone's lock works before relying on it.
    final result = await ref.read(deviceAuthProvider).authenticate('Turn on the app lock');
    if (result == AuthResult.success) {
      await saveLockSettings(ref, s.copyWith(enabled: true));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == AuthResult.unavailable
                ? "Your phone has no screen lock, so the app lock can't be turned on."
                : "Not turned on. Your phone didn't confirm it was you.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(lockSettingsProvider).valueOrNull ?? const LockSettings();
    final available = ref.watch(lockAvailableProvider).valueOrNull ?? true;
    final removed = s.enabled && ref.watch(lockProvider.select((l) => l.unavailable));
    final noLock = !available || removed;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            'App lock',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keeps other people out of Amrutham when they pick up your phone.',
            style: TextStyle(color: onboardMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (noLock) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBEFD2),
                border: Border.all(color: onboardAmber),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_outline, color: Color(0xFF6B4A00)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your phone has no screen lock',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF4A3300)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    removed
                        ? "Your phone's screen lock was removed, so Amrutham opened without asking. "
                              'Set a fingerprint, PIN or pattern in your phone\'s settings and it will lock again.'
                        : "Amrutham borrows your phone's lock, so it needs one. Set a fingerprint, PIN or "
                              "pattern in your phone's settings, then come back and turn this on.",
                    style: const TextStyle(color: Color(0xFF4A3300), height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  OnboardButton(label: 'Open phone settings', onPressed: SecureScreen.openSecuritySettings),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Opacity(
            opacity: available ? 1 : 0.55,
            child: Card(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                title: const Text('Lock Amrutham', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text(
                  "Uses your phone's fingerprint, face or screen lock. There is no separate PIN.",
                ),
                value: s.enabled && !removed,
                onChanged: available
                    ? (on) => on ? _turnOn(context, ref, s) : saveLockSettings(ref, s.copyWith(enabled: false))
                    : null,
              ),
            ),
          ),
          if (s.enabled && !noLock) ...[
            const SectionLabel('Lock after you leave the app'),
            Card(
              child: RadioGroup<LockTimeout>(
                groupValue: s.timeout,
                onChanged: (v) => saveLockSettings(ref, s.copyWith(timeout: v)),
                child: Column(
                  children: [
                    for (final t in LockTimeout.values)
                      RadioListTile<LockTimeout>(
                        value: t,
                        title: Text(t.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: t.hint == null ? null : Text(t.hint!),
                      ),
                  ],
                ),
              ),
            ),
            const SectionLabel('Privacy'),
            Card(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                title: const Text('Hide Amrutham in recent apps', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text(
                  'The app switcher shows a blank card instead of your records. Also stops screenshots.',
                ),
                value: s.hideInRecents,
                onChanged: (v) => saveLockSettings(ref, s.copyWith(hideInRecents: v)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            noLock && !available
                ? 'If you remove your phone\'s screen lock later, Amrutham opens without asking and says why here, '
                      'instead of locking you out of your own records.'
                : 'The emergency card and your medicine reminders work while Amrutham is locked.',
            style: const TextStyle(color: onboardMuted, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
