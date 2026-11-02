import 'dart:convert';

import '../crypto/onboarding_store.dart';

/// Where an alarm's sound comes from. Android can't change a channel's sound
/// after it is made, so each choice is its own channel (see [AlarmSettings.channelId]).
enum AlarmSound {
  alarm('Phone alarm tone', 'The tone you use for your alarm clock', 'content://settings/system/alarm_alert'),
  notification('Phone notification tone', 'A shorter, softer sound', 'content://settings/system/notification_sound'),
  ringtone('Phone ringtone', 'Rings like an incoming call', 'content://settings/system/ringtone'),
  none('Vibrate only', 'No sound at all', null);

  const AlarmSound(this.label, this.hint, this.uri);
  final String label, hint;
  final String? uri;
}

const snoozeChoices = [5, 10, 15];
const ringChoices = [5, 10, 20];

/// What the person chose about how alarms ring. Device-local, like the lock.
class AlarmSettings {
  const AlarmSettings({this.sound = AlarmSound.alarm, this.vibrate = true, this.snoozeMinutes = 10, this.ringMinutes = 10});

  final AlarmSound sound;
  final bool vibrate;
  final int snoozeMinutes;
  final int ringMinutes;

  static const storeKey = 'alarm_settings';

  /// Bumped whenever how alarms are built changes, so older ones are re-armed.
  static const version = 'v3';

  String get channelId => 'meds_alarm_${version}_${sound.name}_${vibrate ? 'v' : 'q'}';

  /// Every channel this build can make, so the unused ones can be removed.
  static List<String> get allChannelIds => [
    for (final s in AlarmSound.values)
      for (final v in [true, false]) 'meds_alarm_${version}_${s.name}_${v ? 'v' : 'q'}',
  ];

  AlarmSettings copyWith({AlarmSound? sound, bool? vibrate, int? snoozeMinutes, int? ringMinutes}) => AlarmSettings(
    sound: sound ?? this.sound,
    vibrate: vibrate ?? this.vibrate,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    ringMinutes: ringMinutes ?? this.ringMinutes,
  );

  String encode() => jsonEncode({'s': sound.name, 'v': vibrate, 'z': snoozeMinutes, 'r': ringMinutes});

  static AlarmSettings decode(String? raw) {
    if (raw == null) return const AlarmSettings();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return AlarmSettings(
        sound: AlarmSound.values.asNameMap()[m['s']] ?? AlarmSound.alarm,
        vibrate: m['v'] as bool? ?? true,
        snoozeMinutes: snoozeChoices.contains(m['z']) ? m['z'] as int : 10,
        ringMinutes: ringChoices.contains(m['r']) ? m['r'] as int : 10,
      );
    } catch (_) {
      return const AlarmSettings();
    }
  }

  static Future<AlarmSettings> load(OnboardingStore store) async => decode(await store.setting(storeKey));

  Future<void> save(OnboardingStore store) => store.putSetting(storeKey, encode());
}

/// "08:00" -> "8:00 am", "21:00" -> "9:00 pm".
({String clock, String ampm}) twelveHour(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.parse(parts[0]);
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return (clock: '$h12:${parts[1]}', ampm: h < 12 ? 'am' : 'pm');
}
