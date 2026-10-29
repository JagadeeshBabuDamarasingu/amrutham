import 'ids.dart';

/// What can be logged. The unit and whether there is a second number live
/// here so the log form and the charts stay in step.
enum MeasurementKind {
  weight('Weight', 'kg'),
  bloodPressure('Blood pressure', 'mmHg', secondLabel: 'Bottom', firstLabel: 'Top'),
  bloodSugar('Sugar', 'mg/dL'),
  steps('Steps', 'steps'),
  sleep('Sleep', 'hours');

  const MeasurementKind(
    this.label,
    this.unit, {
    this.firstLabel = 'Value',
    this.secondLabel,
  });

  final String label;
  final String unit;
  final String firstLabel;

  /// Non-null for kinds recorded as two numbers (blood pressure: 128 / 82).
  final String? secondLabel;

  bool get hasSecondValue => secondLabel != null;
}

class Measurement {
  final MeasurementId id;
  final PersonId personId;
  final MeasurementKind kind;
  final double value;
  final double? value2;
  final DateTime measuredAt;
  final String? note;

  const Measurement({
    required this.id,
    required this.personId,
    required this.kind,
    required this.value,
    this.value2,
    required this.measuredAt,
    this.note,
  });

  /// "128/82", "71.4", "6h 40m" — exactly what was entered, no judgement.
  String get display => formatReading(kind, value, value2);
}

String formatReading(MeasurementKind kind, double value, [double? value2]) {
  String n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  switch (kind) {
    case MeasurementKind.bloodPressure:
      return '${n(value)}/${n(value2 ?? 0)}';
    case MeasurementKind.sleep:
      final minutes = (value * 60).round();
      return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
    default:
      return n(value);
  }
}
