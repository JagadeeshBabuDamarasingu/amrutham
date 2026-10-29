import 'ids.dart';

enum RecordType {
  prescription('Prescription'),
  labReport('Lab report'),
  scan('Scan'),
  bill('Bill'),
  discharge('Discharge'),
  other('Other');

  const RecordType(this.label);
  final String label;
}

class HealthRecord {
  final RecordId id;
  final PersonId personId;
  final RecordType type;
  final String title;
  final DateTime recordDate;
  final String? source;

  /// Paths relative to the vault folder.
  final List<String> files;
  final DateTime addedAt;

  const HealthRecord({
    required this.id,
    required this.personId,
    required this.type,
    required this.title,
    required this.recordDate,
    this.source,
    required this.files,
    required this.addedAt,
  });
}
