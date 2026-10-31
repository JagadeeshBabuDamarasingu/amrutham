import 'expense.dart';
import 'history_event.dart';
import 'ids.dart';

enum CareKind { doctor, facility }

class CareProvider {
  final CareProviderId id;
  final CareKind kind;
  final String name;
  final String? specialty;
  final String? worksAt;
  final String? phone;
  final String? location;
  final List<PersonId> personIds;
  final bool isCurrent;

  const CareProvider({
    required this.id,
    required this.kind,
    required this.name,
    this.specialty,
    this.worksAt,
    this.phone,
    this.location,
    required this.personIds,
    required this.isCurrent,
  });
}

/// A name reduced for comparing: case, "Dr." and punctuation don't matter, so
/// "Dr. S. Rao" and "S Rao" are the same doctor.
String careNameKey(String name) => name
    .toLowerCase()
    .replaceAll(RegExp(r'[.,]'), ' ')
    .replaceFirst(RegExp(r'^\s*dr\s+'), '')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

/// An entry in [all] of the same kind that [name] already refers to.
CareProvider? sameProvider(
  Iterable<CareProvider> all,
  CareKind kind,
  String name, {
  CareProviderId? except,
}) {
  final key = careNameKey(name);
  if (key.isEmpty) return null;
  return all
      .where((p) => p.kind == kind && p.id != except && careNameKey(p.name) == key)
      .firstOrNull;
}

/// What the app already knows about one doctor or place, drawn from the history
/// and the expenses. They are matched by name, since entries only carry the name
/// they were typed with; "Dr. S. Rao" and "S Rao" match, as in [careNameKey].
class CareSummary {
  const CareSummary({this.lastVisit, this.nextVisit, this.visits = 0, this.spentThisYear = 0});

  final HistoryEvent? lastVisit;
  final HistoryEvent? nextVisit;
  final int visits;

  /// In paise, this calendar year, for the people this provider is shared with.
  final int spentThisYear;
}

CareSummary summarizeCare(
  CareProvider p,
  Iterable<HistoryEvent> events,
  Iterable<Expense> expenses,
  DateTime now,
) {
  final key = careNameKey(p.name);
  final mine = [
    for (final e in events)
      if (e.provider != null && careNameKey(e.provider!) == key && p.personIds.contains(e.personId)) e,
  ]..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  final past = mine.where((e) => !e.eventDate.isAfter(now)).toList();
  final future = mine.where((e) => e.eventDate.isAfter(now)).toList();
  var spent = 0;
  for (final x in expenses) {
    if (x.payee != null &&
        careNameKey(x.payee!) == key &&
        x.spentOn.year == now.year &&
        p.personIds.contains(x.personId)) {
      spent += x.amountPaise;
    }
  }
  return CareSummary(
    lastVisit: past.isEmpty ? null : past.last,
    nextVisit: future.isEmpty ? null : future.first,
    visits: past.length,
    spentThisYear: spent,
  );
}

/// Two letters for the round badge: "Dr. S. Rao" is "SR".
String careInitials(String name) => name
    .replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '')
    .split(' ')
    .where((w) => w.isNotEmpty)
    .take(2)
    .map((w) => w[0].toUpperCase())
    .join();
