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

  /// Asks the launcher to add a widget for [personId]: `card` (the full emergency
  /// card), `dial` (one big dial button) or `blood` (blood group and allergies). False when the launcher
  /// can't be asked; the person then adds it from the widget list.
  static Future<bool> pinCard(String personId, {String kind = 'card'}) async {
    try {
      return await _channel.invokeMethod<bool>('pinCard', {'personId': personId, 'kind': kind}) ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Pins a notification on the lock screen. [dials] become buttons that open
  /// the dialer with the number filled in.
  static Future<void> showLockNotice({
    required int id,
    required String title,
    required String short,
    required String shortBody,
    required String body,
    required List<({String label, String number})> dials,
  }) async {
    try {
      await _channel.invokeMethod<void>('showLockNotice', {
        'id': id,
        'title': title,
        'short': short,
        'shortBody': shortBody,
        'body': body,
        'dials': [for (final d in dials) {'label': d.label, 'number': d.number}],
      });
    } on MissingPluginException {
      // Not Android (or a test).
    }
  }

  static Future<void> hideLockNotice(int id) async {
    try {
      await _channel.invokeMethod<void>('hideLockNotice', {'id': id});
    } on MissingPluginException {
      // Not Android (or a test).
    }
  }

  /// Opens Android's own Medical info screen (the one the lock screen's
  /// Emergency button shows). False if this phone has no such screen.
  static Future<bool> openMedicalInfo() async {
    try {
      return await _channel.invokeMethod<bool>('openMedicalInfo') ?? false;
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
