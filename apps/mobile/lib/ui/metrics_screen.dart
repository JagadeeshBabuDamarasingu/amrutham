import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/ids.dart';
import '../model/measurement.dart';
import '../providers/app_providers.dart';
import 'log_measurement_screen.dart';
import 'app_style.dart';
import 'item_actions.dart';

/// Daily metrics for one person: a chart of the chosen kind, the latest of
/// every kind, and the readings behind them. Values are shown exactly as
/// logged — never labelled normal/high/low or improving/declining.
class MetricsScreen extends ConsumerStatefulWidget {
  const MetricsScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  ConsumerState<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends ConsumerState<MetricsScreen> {
  MeasurementKind _kind = MeasurementKind.weight;
  int _days = 30;

  void _log([MeasurementKind? kind]) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LogMeasurementScreen(
        personId: widget.personId,
        initialKind: kind ?? _kind,
      ),
    ),
  );

  Future<void> _actions(Measurement m) => showItemActions(
    context,
    title: '${m.kind.label} ${m.display} ${m.kind.unit}, ${dateLabel(m.measuredAt)}',
    deleteTitle: 'Delete this reading?',
    onEdit: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LogMeasurementScreen(personId: widget.personId, editing: m),
      ),
    ),
    onDelete: () async {
      final repository = await ref.read(measurementRepositoryProvider.future);
      await repository.deleteMeasurement(m.id);
    },
  );

  @override
  Widget build(BuildContext context) {
    final readings = ref.watch(measurementsProvider(widget.personId));
    final name = ref
        .watch(profilesProvider)
        .valueOrNull
        ?.where((p) => p.id == widget.personId)
        .firstOrNull
        ?.displayName;

    return Scaffold(
      backgroundColor: onboardBg,
      appBar: AppBar(
        backgroundColor: onboardBg,
        title: Text(name == null ? 'Daily metrics' : '$name · metrics'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _log,
        backgroundColor: onboardInk,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log today'),
      ),
      body: readings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong: $e')),
        data: (all) {
          final ofKind = all.where((m) => m.kind == _kind).toList();
          final since = DateTime.now().subtract(Duration(days: _days));
          final inRange = ofKind
              .where((m) => m.measuredAt.isAfter(since))
              .toList()
              .reversed
              .toList(); // oldest first for the chart
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final kind in MeasurementKind.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(kind.label),
                          selected: kind == _kind,
                          onSelected: (_) => setState(() => _kind = kind),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ChartCard(
                kind: _kind,
                latest: ofKind.firstOrNull,
                points: inRange,
                days: _days,
                onDays: (d) => setState(() => _days = d),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  for (final kind in MeasurementKind.values)
                    if (kind != _kind)
                      _LatestTile(
                        kind: kind,
                        latest: all.where((m) => m.kind == kind).firstOrNull,
                        onTap: () => setState(() => _kind = kind),
                      ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${_kind.label.toUpperCase()} READINGS',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: onboardMuted,
                ),
              ),
              if (ofKind.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Nothing logged yet. Tap "Log today".'),
                ),
              for (final m in ofKind.take(30))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${m.display} ${m.kind.unit}'),
                  subtitle: Text(
                    '${dateLabel(m.measuredAt)}, '
                    '${TimeOfDay.fromDateTime(m.measuredAt).format(context)}',
                  ),
                  trailing: const Icon(Icons.more_horiz),
                  onTap: () => _actions(m),
                ),
              const SizedBox(height: 12),
              const Text(
                'Shown exactly as logged. Amrutham does not label values as '
                'normal, high, low, improving or declining.',
                style: TextStyle(fontSize: 13, height: 1.4, color: onboardMuted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.kind,
    required this.latest,
    required this.points,
    required this.days,
    required this.onDays,
  });

  final MeasurementKind kind;
  final Measurement? latest;
  final List<Measurement> points; // oldest first, already range-filtered
  final int days;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${kind.label.toUpperCase()} · LATEST',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: onboardMuted,
                    ),
                  ),
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7D')),
                    ButtonSegment(value: 30, label: Text('30D')),
                    ButtonSegment(value: 90, label: Text('90D')),
                  ],
                  selected: {days},
                  onSelectionChanged: (s) => onDays(s.first),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: latest?.display ?? '—',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: latest == null ? '' : ' ${kind.unit}',
                    style: const TextStyle(fontSize: 16, color: onboardMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: points.isEmpty
                  ? const Center(child: Text('No readings in this range.'))
                  : CustomPaint(
                      size: Size.infinite,
                      painter: _LinePainter(points: points, days: days),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestTile extends StatelessWidget {
  const _LatestTile({
    required this.kind,
    required this.latest,
    required this.onTap,
  });

  final MeasurementKind kind;
  final Measurement? latest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kind.label, style: const TextStyle(color: onboardMuted)),
            const Spacer(),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: latest?.display ?? '—',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (latest != null)
                    TextSpan(
                      text: ' ${kind.unit}',
                      style: const TextStyle(fontSize: 12, color: onboardMuted),
                    ),
                ],
              ),
            ),
            Text(
              latest == null ? 'Not logged' : dateLabel(latest!.measuredAt),
              style: const TextStyle(fontSize: 12, color: onboardMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A plain line chart: one line, or two for blood pressure. Time runs left to
/// right over the chosen range; the newest reading gets the amber dot.
class _LinePainter extends CustomPainter {
  _LinePainter({required this.points, required this.days});

  final List<Measurement> points;
  final int days;

  @override
  void paint(Canvas canvas, Size size) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    final span = end.difference(start).inMilliseconds.toDouble();

    final values = [
      for (final m in points) ...[m.value, ?m.value2],
    ];
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.15;
    lo -= pad;
    hi += pad;

    const bottomInset = 4.0;
    Offset at(DateTime t, double v) => Offset(
      t.difference(start).inMilliseconds / span * size.width,
      (size.height - bottomInset) * (1 - (v - lo) / (hi - lo)),
    );

    final grid = Paint()
      ..color = const Color(0xFFE3ECE7)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = (size.height - bottomInset) * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    void line(double Function(Measurement) pick, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final o = at(points[i].measuredAt, pick(points[i]));
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, paint);
      for (final m in points) {
        canvas.drawCircle(at(m.measuredAt, pick(m)), 3, Paint()..color = color);
      }
    }

    line((m) => m.value, onboardInk);
    if (points.first.kind.hasSecondValue) {
      line((m) => m.value2 ?? m.value, const Color(0xFF7FA08F));
    }
    final newest = points.last;
    canvas.drawCircle(
      at(newest.measuredAt, newest.value),
      5.5,
      Paint()..color = onboardAmber,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points || old.days != days;
}
