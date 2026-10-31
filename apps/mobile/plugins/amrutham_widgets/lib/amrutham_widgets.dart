import 'package:flutter/services.dart';

/// The app's side of the home screen emergency cards. The native side keeps a
/// small copy of what each card may show in the phone's preferences (excluded
/// from Android's cloud backup) and draws the widgets from it.
class AmruthamWidgets {
  static const _channel = MethodChannel('app.amrutham/widgets');

  /// Replaces everything the widgets know. [snapshots] holds one JSON text per
  /// person id; an empty [enabled] = false wipes the copy.
  static Future<void> sync({
    required bool enabled,
    required List<({String id, String name})> people,
    required Map<String, String> snapshots,
  }) async {
    try {
      await _channel.invokeMethod<void>('sync', {
        'enabled': enabled,
        'people': [for (final p in people) {'id': p.id, 'name': p.name}],
        'snapshots': snapshots,
      });
    } on MissingPluginException {
      // Not Android (or a test): there are no widgets to update.
    }
  }

  /// How many cards each person has on the home screen, by person id.
  static Future<Map<String, int>> cardCounts() async {
    try {
      final raw = await _channel.invokeMapMethod<String, int>('cardCounts');
      return raw ?? {};
    } on MissingPluginException {
      return {};
    }
  }

  /// Asks the launcher to add a card for [personId]. False when the launcher
  /// can't be asked; the person then adds it from the widget list.
  static Future<bool> pinCard(String personId) async {
    try {
      return await _channel.invokeMethod<bool>('pinCard', {'personId': personId}) ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// What launched the app, once: `{'action': 'emergency', 'personId': ...}`.
  static Future<Map<String, String>?> initialAction() async {
    try {
      return await _channel.invokeMapMethod<String, String>('initialAction');
    } on MissingPluginException {
      return null;
    }
  }

  /// Calls [onAction] when a widget is tapped while the app is already open.
  static void listen(void Function(Map<String, String> action) onAction) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        onAction((call.arguments as Map).cast<String, String>());
      }
    });
  }
}
