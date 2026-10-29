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
