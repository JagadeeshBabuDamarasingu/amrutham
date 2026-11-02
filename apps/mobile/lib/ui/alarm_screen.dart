import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../medicine/medicine_photo.dart';
import '../model/dose_log.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import '../reminder/alarm_actions.dart';
import '../reminder/alarm_settings.dart';
import 'app_style.dart';

class _Item {
  _Item(this.payload, this.person);
  final AlarmPayload payload;
  final String person;
  bool done = false;
  File? photo;
}

/// The doses due at [hhmm] today that nobody has answered yet, so one alarm
/// can cover everything that is due together.
List<TodayDose> dosesDueTogether(
  List<TodayDose> doses,
  Set<String> answered,
  String hhmm,
) => [
  for (final d in doses)
    if ('${d.time.hour.toString().padLeft(2, '0')}:${d.time.minute.toString().padLeft(2, '0')}' ==
            hhmm &&
        !answered.contains(DoseLog.keyFor(d.courseId, d.scheduledAt)))
      d,
];

/// What opens over everything when a medicine alarm rings: the time, what to
/// take, and big buttons. Doses due together are listed on one page.
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key, required this.ring});

  final AlarmRing ring;

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  AlarmRing get ring => widget.ring;
  List<_Item>? _items;
  var _settings = const AlarmSettings();

  @override
  void initState() {
    super.initState();
    alarmShowing.value = true;
    _load();
  }

  @override
  void dispose() {
    alarmShowing.value = false;
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await AlarmSettings.load(
      ref.read(onboardingStoreProvider),
    );
    var items = <_Item>[];
    try {
      final doses = await ref.read(todaysDosesProvider.future);
      final logs = await ref.read(todaysDoseLogsProvider.future);
      final due = dosesDueTogether(doses, {
        for (final l in logs) l.key,
      }, ring.payload.time);
      items = [
        for (final d in due)
          _Item(
            AlarmPayload(
              d.person.id.value,
              d.courseId.value,
              ring.payload.time,
              d.medicationName,
              d.doseAmount,
            ),
            d.person.displayName,
          ),
      ];
    } catch (_) {
      // No database to ask (for instance a test alarm): fall back to the one dose.
    }
    if (items.isEmpty) {
      final people = ref.read(profilesProvider).valueOrNull ?? const [];
      final who =
          people
              .where((p) => p.id.value == ring.payload.personId)
              .firstOrNull
              ?.displayName ??
          '';
      items = [_Item(ring.payload, who)];
    }
    final vault = await ref.read(vaultDirectoryProvider.future);
    for (final i in items) {
      final f = medicinePhotoFile(vault, MedicationCourseId(i.payload.courseId));
      if (await f.exists()) i.photo = f;
    }
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _items = items;
    });
  }

  Iterable<_Item> get _left =>
      (_items ?? const <_Item>[]).where((i) => !i.done);

  /// Closes the page when nothing is left: stops the ringing and sets the
  /// repeating alarms again (stopping one removes its schedule).
  Future<void> _finishIfDone() async {
    if (_left.isNotEmpty) return;
    final id = ring.notificationId;
    if (id != null) await FlutterLocalNotificationsPlugin().cancel(id: id);
    try {
      final reminders = await ref.read(reminderRepositoryProvider.future);
      for (final person in {for (final i in _items!) i.payload.personId}) {
        if (person != 'test')
          await reminders.armRemindersForPerson(PersonId(person));
      }
    } catch (_) {}
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _answerAll(Future<void> Function(AlarmPayload p) go) async {
    for (final i in _left.toList()) {
      await go(i.payload);
      i.done = true;
    }
    if (mounted) setState(() {});
    await _finishIfDone();
  }

  Future<void> _tick(_Item item) async {
    await answerDose(item.payload, DoseStatus.taken);
    setState(() => item.done = true);
    await _finishIfDone();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items ?? [_Item(ring.payload, '')];
    final many = items.length > 1;
    final left = _left.length;
    final t = twelveHour(ring.payload.time);

    Widget button(
      String label,
      Color bg,
      Color fg,
      VoidCallback go, {
      Widget? icon,
      double h = 56,
      bool outline = false,
    }) => SizedBox(
      width: double.infinity,
      height: h,
      child: FilledButton.icon(
        icon: icon ?? const SizedBox.shrink(),
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: outline
                ? BorderSide(color: Colors.white.withValues(alpha: 0.2))
                : BorderSide.none,
          ),
          textStyle: TextStyle(
            fontSize: h > 60 ? 21 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: go,
        label: Text(label),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF17302A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.45),
            radius: 1.0,
            colors: [Color(0xFF2F5A4B), Color(0xFF17302A)],
            stops: [0, 0.65],
          ),
        ),
        child: SafeArea(
          // Scrolls on a small phone or with large text, so no button is cut off.
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      children: [
                        if (!many && items.first.person.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'MEDICINE ALARM · ${items.first.person.toUpperCase()}',
                              style: const TextStyle(
                                color: Color(0xFF9FC0B2),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        SizedBox(
                          height: many ? 96 : (items.first.photo != null ? 232 : 190),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (!many)
                                for (final (d, a) in items.first.photo != null
                                    ? [(226.0, 0.12), (196.0, 0.22), (166.0, 0.4)]
                                    : [(200.0, 0.12), (150.0, 0.22), (104.0, 0.4)])
                                  Container(
                                    width: d,
                                    height: d,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: d == 104 || d == 166
                                          ? onboardAmber.withValues(alpha: 0.08)
                                          : null,
                                      border: Border.all(
                                        color: onboardAmber.withValues(
                                          alpha: a,
                                        ),
                                      ),
                                    ),
                                  ),
                              if (!many && items.first.photo != null)
                                ClipOval(
                                  child: Image.file(
                                    items.first.photo!,
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    semanticLabel: 'Photo of ${items.first.payload.name}',
                                  ),
                                )
                              else
                                Icon(
                                  Icons.notifications_none,
                                  size: many ? 34 : 46,
                                  color: onboardAmber,
                                ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              t.clock,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: many ? 72 : 84,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -2.5,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t.ampm,
                              style: const TextStyle(
                                color: Color(0xFFCFE0D8),
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (many) ...[
                          Text(
                            '$left medicine${left == 1 ? '' : 's'} to take',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tick each one as you take it.',
                            style: TextStyle(
                              color: Color(0xFFCFE0D8),
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              children: [
                                for (final item in items)
                                  ListTile(
                                    leading: item.photo == null
                                        ? null
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.file(item.photo!, width: 52, height: 52, fit: BoxFit.cover),
                                          ),
                                    title: Text(
                                      '${item.payload.name} ${item.payload.dose}'
                                          .trim(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        decoration: item.done
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      item.person,
                                      style: const TextStyle(
                                        color: Color(0xFF9FC0B2),
                                      ),
                                    ),
                                    trailing: item.done
                                        ? Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: onboardAmber,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Color(0xFF2A1D00),
                                            ),
                                          )
                                        : Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.white38,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                    onTap: item.done ? null : () => _tick(item),
                                  ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ] else ...[
                          const Text(
                            'TIME TO TAKE',
                            style: TextStyle(
                              color: Color(0xFF9FC0B2),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            items.first.payload.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                          ),
                          if (items.first.payload.dose.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              items.first.payload.dose,
                              style: const TextStyle(
                                color: Color(0xFFCFE0D8),
                                fontSize: 18,
                              ),
                            ),
                          ],
                          const Spacer(),
                        ],
                        button(
                          many ? 'Taken: the $left left' : 'Taken',
                          onboardAmber,
                          const Color(0xFF2A1D00),
                          () => _answerAll(
                            (p) => answerDose(p, DoseStatus.taken),
                          ),
                          h: 68,
                          icon: many ? null : const Icon(Icons.check, size: 26),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 12,
                              child: button(
                                'Snooze ${_settings.snoozeMinutes} min',
                                Colors.white.withValues(alpha: 0.12),
                                Colors.white,
                                () => _answerAll(snoozeAlarm),
                                outline: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 10,
                              child: button(
                                many ? 'Skip the rest' : 'Skip this dose',
                                Colors.transparent,
                                const Color(0xFFB8D0C5),
                                () => _answerAll(
                                  (p) => answerDose(p, DoseStatus.missed),
                                ),
                                outline: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          many
                              ? 'Doses due together are grouped, so one alarm rings once.'
                              : 'Opens without unlocking. The rest of Amrutham stays locked. Rings for ${_settings.ringMinutes} minutes or until you answer.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF9FC0B2),
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
