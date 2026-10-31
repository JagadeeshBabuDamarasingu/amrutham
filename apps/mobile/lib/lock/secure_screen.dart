import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Window-level settings that only the Android activity can change.
class SecureScreen {
  static const _channel = MethodChannel('app.amrutham/secure');

  /// Blank card in the app switcher, and no screenshots. Left off in debug
  /// builds so development screenshots keep working.
  static Future<void> hideContent(bool on) async {
    if (kDebugMode) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'on': on});
    } on MissingPluginException {
      // Not Android, or a test.
    }
  }

  /// Opens the phone's own security settings, to set a screen lock.
  static Future<void> openSecuritySettings() async {
    try {
      await _channel.invokeMethod<void>('openSecuritySettings');
    } on MissingPluginException {
      // Nothing to open.
    }
  }
}
