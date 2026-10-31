import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  Route<void>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(lockProvider.notifier).start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = ref.read(lockProvider.notifier);
    if (state == AppLifecycleState.paused) lock.leftApp();
    if (state == AppLifecycleState.resumed) lock.returnedToApp();
  }

  void _sync(AppLockState lock) {
    if (lock.locked && _route == null) _show();
    if (!lock.locked && _route != null) _hide();
  }

  void _show() {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      // The navigator is built a frame after the gate: try again then.
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync(ref.read(lockProvider)));
      return;
    }
    final route = PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const LockHost(),
    );
    _route = route;
    navigator.push(route);
  }

  void _hide() {
    final route = _route;
    _route = null;
    if (route != null && route.navigator != null) route.navigator!.removeRoute(route);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(lockProvider, (_, next) => _sync(next));
    ref.listen(lockSettingsProvider, (_, next) {
      next.whenData((s) {
        SecureScreen.hideContent(s.enabled && s.hideInRecents);
        ref.read(lockProvider.notifier).settingsChanged();
      });
    });
    final checking = ref.watch(lockProvider.select((s) => s.checking));
    return Stack(
      children: [
        widget.child,
        if (checking) const Positioned.fill(child: ColoredBox(color: Color(0xFF17302A))),
      ],
    );
  }
}
