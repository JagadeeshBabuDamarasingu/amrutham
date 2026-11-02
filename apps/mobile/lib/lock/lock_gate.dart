import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../reminder/alarm_actions.dart';
import '../ui/alarm_screen.dart';
import 'app_navigator.dart';
import 'lock_controller.dart';
import 'lock_screen.dart';
import 'secure_screen.dart';

/// Wraps the whole app. It decides at start-up whether the app is locked, locks
/// again when the app has been out of sight too long, and covers everything
/// with the lock route while it is locked. Until it has decided, the app is
/// covered so nothing flashes.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(lockProvider.notifier).start());
    pendingRing.addListener(_showRing);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showRing());
  }

  /// A ringing alarm opens its page: over the lock screen when locked (it
  /// only shows the medicine and three buttons), otherwise over the app.
  void _showRing() {
    final ring = pendingRing.value;
    if (ring == null || !mounted || ref.read(lockProvider).checking) return;
    final state = ref.read(lockProvider);
    final nav = state.locked ? lockNavigator.currentState : appNavigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRing());
      return;
    }
    pendingRing.value = null;
    nav.push(MaterialPageRoute<void>(builder: (_) => AlarmScreen(ring: ring)));
  }

  @override
  void dispose() {
    pendingRing.removeListener(_showRing);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = ref.read(lockProvider.notifier);
    if (state == AppLifecycleState.paused) lock.leftApp();
    if (state == AppLifecycleState.resumed) lock.returnedToApp();
  }

  /// Back must never reach the app underneath. The lock is not a route (a
  /// route can be replaced by the app's own navigation, e.g. the splash
  /// screen), so back is caught here and passed to the lock's own navigator.
  @override
  Future<bool> didPopRoute() async {
    if (!ref.read(lockProvider).locked) return false;
    await lockNavigator.currentState?.maybePop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(lockSettingsProvider, (_, next) {
      next.whenData((s) {
        SecureScreen.hideContent(s.enabled && s.hideInRecents);
        ref.read(lockProvider.notifier).settingsChanged();
      });
    });
    ref.listen(lockProvider.select((s) => s.checking), (_, now) {
      if (!now) WidgetsBinding.instance.addPostFrameCallback((_) => _showRing());
    });
    final checking = ref.watch(lockProvider.select((s) => s.checking));
    final locked = ref.watch(lockProvider.select((s) => s.locked));
    return Stack(
      children: [
        ExcludeFocus(
          excluding: locked,
          child: Offstage(offstage: locked, child: widget.child),
        ),
        if (locked) const Positioned.fill(child: LockHost()),
        if (checking) const Positioned.fill(child: ColoredBox(color: Color(0xFF17302A))),
      ],
    );
  }
}
