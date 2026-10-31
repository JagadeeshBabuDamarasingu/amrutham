import 'dart:convert';

/// How long Amrutham may be out of sight before it asks again.
enum LockTimeout {
  immediately('Right away', 'Every time you come back', Duration.zero),
  oneMinute('1 minute', 'Switching to another app and back is fine', Duration(minutes: 1)),
  fiveMinutes('5 minutes', null, Duration(minutes: 5)),
  fifteenMinutes('15 minutes', null, Duration(minutes: 15));

  const LockTimeout(this.label, this.hint, this.after);

  final String label;
  final String? hint;
  final Duration after;
}

/// Device-local choices for the app lock, kept in the small settings store and
/// not in the database, so a restore never turns a lock on or off. It starts
/// off until the person agrees to it.
class LockSettings {
  const LockSettings({
    this.enabled = false,
    this.timeout = LockTimeout.oneMinute,
    this.hideInRecents = true,
  });

  final bool enabled;
  final LockTimeout timeout;

  /// Blank card in the app switcher, and no screenshots, while the lock is on.
  final bool hideInRecents;

  static const storeKey = 'app_lock';

  /// Set once the question at the end of onboarding has been answered, either way.
  static const askedKey = 'app_lock_asked';

  LockSettings copyWith({bool? enabled, LockTimeout? timeout, bool? hideInRecents}) => LockSettings(
    enabled: enabled ?? this.enabled,
    timeout: timeout ?? this.timeout,
    hideInRecents: hideInRecents ?? this.hideInRecents,
  );

  String encode() => jsonEncode({
    'enabled': enabled,
    'timeout': timeout.name,
    'hideInRecents': hideInRecents,
  });

  /// A missing or damaged value means off: never a lock that can't be opened.
  static LockSettings decode(String? stored) {
    if (stored == null) return const LockSettings();
    try {
      final j = jsonDecode(stored) as Map<String, dynamic>;
      return LockSettings(
        enabled: j['enabled'] as bool? ?? false,
        timeout: LockTimeout.values.asNameMap()[j['timeout']] ?? LockTimeout.oneMinute,
        hideInRecents: j['hideInRecents'] as bool? ?? true,
      );
    } on Object {
      return const LockSettings();
    }
  }
}
