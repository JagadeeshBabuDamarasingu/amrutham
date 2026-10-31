import '../model/ids.dart';

/// Where a home screen tap (a widget, or an app-icon shortcut) should land.
enum LaunchKind { emergencyCard, logReading, nextDose, addRecord }

class LaunchTarget {
  const LaunchTarget(this.kind, [this.personId]);

  final LaunchKind kind;

  /// Null only for [LaunchKind.nextDose], which opens Today.
  final PersonId? personId;

  @override
  bool operator ==(Object other) =>
      other is LaunchTarget && other.kind == kind && other.personId == personId;

  @override
  int get hashCode => Object.hash(kind, personId);
}

/// Turns what the phone handed over (`{'action': ..., 'personId': ...}`) into a
/// destination, or null when there is nowhere sensible to go. A shortcut can't
/// name a person, so it uses the one picked in the app, else the first living
/// person; a widget names its own, which must still be a living person.
LaunchTarget? resolveLaunch(
  Map<String, String> action, {
  required List<PersonId> living,
  PersonId? selected,
}) {
  final kind = switch (action['action']) {
    'emergency' => LaunchKind.emergencyCard,
    'log-reading' => LaunchKind.logReading,
    'next-dose' => LaunchKind.nextDose,
    'add-record' => LaunchKind.addRecord,
    _ => null,
  };
  if (kind == null) return null;
  if (kind == LaunchKind.nextDose) return const LaunchTarget(LaunchKind.nextDose);

  final named = action['personId'];
  final person = living.where((p) => p.value == named).firstOrNull ??
      (selected != null && living.contains(selected) ? selected : null) ??
      living.firstOrNull;
  return person == null ? null : LaunchTarget(kind, person);
}
