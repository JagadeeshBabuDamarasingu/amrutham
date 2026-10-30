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
