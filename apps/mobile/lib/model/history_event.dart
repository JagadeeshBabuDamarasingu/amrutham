import 'ids.dart';

enum HistoryKind {
  visit('Visit'),
  procedure('Procedure'),
  scan('Scan'),
  vaccine('Vaccine'),
  other('Other');

  const HistoryKind(this.label);
  final String label;
}

class HistoryEvent {
  final HistoryEventId id;
  final PersonId personId;
  final HistoryKind kind;
  final String title;
  final DateTime eventDate;
  final String? provider;
  final String? notes;

  const HistoryEvent({
    required this.id,
    required this.personId,
    required this.kind,
    required this.title,
    required this.eventDate,
    this.provider,
    this.notes,
  });

  /// A date in the future means it hasn't happened yet.
  bool get isPlanned => eventDate.isAfter(DateTime.now());
}
