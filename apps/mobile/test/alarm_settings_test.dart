import 'package:flutter_test/flutter_test.dart';
import 'package:amrutham/reminder/alarm_settings.dart';

void main() {
  test('settings survive being saved, and bad data falls back to the defaults', () {
    const s = AlarmSettings(sound: AlarmSound.none, vibrate: false, snoozeMinutes: 15, ringMinutes: 5);
    final back = AlarmSettings.decode(s.encode());
    expect([back.sound, back.vibrate, back.snoozeMinutes, back.ringMinutes], [AlarmSound.none, false, 15, 5]);
    expect(AlarmSettings.decode(null).sound, AlarmSound.alarm);
    expect(AlarmSettings.decode('nonsense').snoozeMinutes, 10);
    expect(AlarmSettings.decode('{"z":7}').snoozeMinutes, 10);
  });

  test('each sound and vibration choice gets its own channel, since a channel keeps its sound', () {
    expect(const AlarmSettings().channelId, isNot(const AlarmSettings(vibrate: false).channelId));
    expect(const AlarmSettings().channelId, isNot(const AlarmSettings(sound: AlarmSound.ringtone).channelId));
    expect(AlarmSettings.allChannelIds, contains(const AlarmSettings().channelId));
  });

  test('times read as on a clock', () {
    expect(twelveHour('08:00'), (clock: '8:00', ampm: 'am'));
    expect(twelveHour('21:05'), (clock: '9:05', ampm: 'pm'));
    expect(twelveHour('00:30'), (clock: '12:30', ampm: 'am'));
    expect(twelveHour('12:00'), (clock: '12:00', ampm: 'pm'));
  });
}
