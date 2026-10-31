import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../ui/app_style.dart';
import 'device_auth.dart';
import 'lock_controller.dart';
import 'lock_settings.dart';

/// The question at the end of onboarding (frame 14c). Asked once: whatever the
/// answer, it is not asked again. Skipped if the phone has no screen lock to
/// borrow, and asked later instead.
Future<void> maybeAskForLock(BuildContext context, WidgetRef ref) async {
  final store = ref.read(onboardingStoreProvider);
  if (await store.setting(LockSettings.askedKey) != null) return;
  if (!await ref.read(deviceAuthProvider).isAvailable()) return;
  if (!context.mounted) return;
  final yes = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (_) => const _AskSheet(),
  );
  await store.putSetting(LockSettings.askedKey, '1');
  if (yes != true) return;
  // Confirm it works before relying on it, so no one is locked out by a lock
  // that can't be opened.
  if (await ref.read(deviceAuthProvider).authenticate('Turn on the app lock') == AuthResult.success) {
    await saveLockSettings(ref, (await ref.read(lockSettingsProvider.future)).copyWith(enabled: true));
  }
}

class _AskSheet extends StatelessWidget {
  const _AskSheet();

  @override
  Widget build(BuildContext context) {
    Widget point(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 18, color: onboardInk),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14.5, height: 1.4))),
        ],
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFFD5E5DD),
              child: Icon(Icons.lock_outline, color: onboardInk, size: 26),
            ),
            const SizedBox(height: 14),
            const Text(
              "Protect Amrutham with your phone's lock?",
              style: TextStyle(fontFamily: headingFont, fontSize: 26, fontWeight: FontWeight.w700, height: 1.12),
            ),
            const SizedBox(height: 14),
            point('It opens with your fingerprint, face or screen lock. No new PIN to remember.'),
            point('The emergency card stays open, so help can see it.'),
            point('Reminders still arrive while it is locked.'),
            point('You can turn it off in Settings, any time.'),
            const SizedBox(height: 8),
            OnboardButton(label: 'Turn on', onPressed: () => Navigator.pop(context, true)),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
