import '../model/allergy.dart';
import '../model/expense.dart';
import '../model/history_event.dart';
import '../model/measurement.dart';
import '../model/medication.dart';
import '../model/person.dart';
import '../ui/expense_export.dart';

/// Everything one person has in Amrutham, as ordinary text. Not protected.
class PersonData {
  const PersonData(this.person, {this.allergies = const [], this.medicines = const [], this.history = const [], this.measurements = const []});
  final PersonProfile person;
  final List<AllergyRecord> allergies;
  final List<MedicationCourse> medicines;
  final List<HistoryEvent> history;
  final List<Measurement> measurements;
}

String _d(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _q(String? s) => '"${(s ?? '').replaceAll('"', '""')}"';

String _fileSafe(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

/// File name -> contents. A summary and a measurements table for each person
/// chosen, and one expenses table. Plain UTF-8 text, so any phone or computer
/// opens it with no app and no code.
Map<String, String> readableCopy(List<PersonData> people, List<Expense> expenses, List<PersonProfile> everyone) {
  final out = <String, String>{};
  for (final p in people) {
    final n = _fileSafe(p.person.displayName).isEmpty ? p.person.id.value : _fileSafe(p.person.displayName);
    final b = StringBuffer()..writeln(p.person.displayName);
    final person = p.person;
    if (person.dateOfBirth != null) b.writeln('Born: ${_d(person.dateOfBirth!)}');
    if (person.sex != null) b.writeln('Sex: ${person.sex}');
    if (person.bloodGroup != null) b.writeln('Blood group: ${person.bloodGroup}');
    if (person.pregnancyLine != null) b.writeln(person.pregnancyLine);
    b.writeln('\nEmergency contacts');
    for (final c in person.emergencyContacts) {
      b.writeln('- ${c.name}${c.relationship == null ? '' : ' (${c.relationship})'}: ${c.phone}');
    }
    b.writeln('\nAllergies');
    for (final a in p.allergies) {
      b.writeln('- ${a.substance}: ${a.reaction}${a.severity == null ? '' : ', ${a.severity}'}');
    }
    b.writeln('\nMedicines');
    for (final m in p.medicines) {
      b.writeln('- ${m.medicationName} (${m.status.name}) from ${_d(m.startDate)}'
          '${m.endDate == null ? '' : ' to ${_d(m.endDate!)}'}${m.reason == null ? '' : ' for ${m.reason}'}');
    }
    b.writeln('\nHistory');
    final events = [...p.history]..sort((a, b) => a.eventDate.compareTo(b.eventDate));
    for (final e in events) {
      b.writeln('- ${_d(e.eventDate)} ${e.kind.label}: ${e.title}${e.provider == null ? '' : ' (${e.provider})'}');
    }
    out['$n-summary.txt'] = b.toString();

    final m = StringBuffer('Date,Measurement,Value,Second value,Unit,Note\n');
    final readings = [...p.measurements]..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    for (final r in readings) {
      m.writeln('${_d(r.measuredAt)},${_q(r.kind.label)},${r.value},${r.value2 ?? ''},${_q(r.kind.unit)},${_q(r.note)}');
    }
    out['$n-measurements.csv'] = m.toString();
  }
  final ids = {for (final p in people) p.person.id};
  final mine = expenses.where((e) => ids.contains(e.personId)).toList();
  if (mine.isNotEmpty) out['expenses.csv'] = expensesCsv(mine, everyone);
  return out;
}
