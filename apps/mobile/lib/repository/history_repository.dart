import 'package:realm/realm.dart';
import 'package:ulid/ulid.dart';

import '../db/realm_schemas.dart';
import '../model/history_event.dart';
import '../model/ids.dart';

class HistoryRepository {
  final Realm _realm;

  HistoryRepository(this._realm);

  Stream<List<HistoryEvent>> watchEvents(PersonId personId) {
    return _realm
        .query<HistoryEventRow>(
          r'personId == $0 SORT(eventDate DESC)',
          [personId.value],
        )
        .changes
        .map((c) => c.results.map(_fromRow).toList());
  }

  Future<HistoryEvent> addEvent({
    required PersonId personId,
    required HistoryKind kind,
    required String title,
    required DateTime eventDate,
    String? provider,
    String? notes,
  }) async {
    final id = HistoryEventId(Ulid().toString());
    _realm.write(() {
      _realm.add(
        HistoryEventRow(
          id.value,
          personId.value,
          kind.name,
          title,
          eventDate,
          provider: provider,
          notes: notes,
        ),
      );
    });
    return HistoryEvent(
      id: id,
      personId: personId,
      kind: kind,
      title: title,
      eventDate: eventDate,
      provider: provider,
      notes: notes,
    );
  }

  Future<void> updateEvent(
    HistoryEventId id, {
    required HistoryKind kind,
    required String title,
    required DateTime eventDate,
    String? provider,
    String? notes,
  }) async {
    final row = _realm.find<HistoryEventRow>(id.value);
    if (row == null) return;
    _realm.write(() {
      row
        ..kind = kind.name
        ..title = title
        ..eventDate = eventDate
        ..provider = provider
        ..notes = notes;
    });
  }

  Future<void> deleteEvent(HistoryEventId id) async {
    final row = _realm.find<HistoryEventRow>(id.value);
    if (row != null) _realm.write(() => _realm.delete(row));
  }

  HistoryEvent _fromRow(HistoryEventRow row) => HistoryEvent(
    id: HistoryEventId(row.id),
    personId: PersonId(row.personId),
    kind: HistoryKind.values.byName(row.kind),
    title: row.title,
    eventDate: row.eventDate.toLocal(),
    provider: row.provider,
    notes: row.notes,
  );
}
