import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../model/dose_log.dart';
import '../reminder/alarm_actions.dart';
import 'app_style.dart';

/// What opens over everything when a medicine alarm rings: the medicine, the
/// time, and three big buttons.
class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key, required this.ring});

  final AlarmRing ring;

  Future<void> _done(BuildContext context, Future<void> Function() answer) async {
    final id = ring.notificationId;
    if (id != null) await FlutterLocalNotificationsPlugin().cancel(id: id);
    await answer();
    if (context.mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final p = ring.payload;
    Widget button(String label, Color bg, Color fg, Future<void> Function() go) => SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        onPressed: () => _done(context, go),
        child: Text(label),
      ),
    );
    return Scaffold(
      backgroundColor: onboardInk,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.alarm, size: 56, color: onboardAmber),
              const SizedBox(height: 16),
              Text(p.time, style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Time to take', style: TextStyle(color: Color(0xFFB8D0C5), fontSize: 16)),
              const SizedBox(height: 6),
              Text(p.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
              if (p.dose.isNotEmpty)
                Text(p.dose, style: const TextStyle(color: Color(0xFFCFE0D8), fontSize: 20)),
              const Spacer(),
              button('Taken', onboardAmber, const Color(0xFF2A1D00), () => answerDose(p, DoseStatus.taken)),
              const SizedBox(height: 12),
              button('Snooze $snoozeMinutes min', Colors.white.withValues(alpha: 0.14), Colors.white, () => snoozeAlarm(p)),
              const SizedBox(height: 12),
              button('Skip this dose', Colors.transparent, const Color(0xFFB8D0C5), () => answerDose(p, DoseStatus.missed)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
