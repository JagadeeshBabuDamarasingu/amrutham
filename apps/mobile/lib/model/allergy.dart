import 'certainty.dart';
import 'ids.dart';

/// Not defined in the original spec (specs/phase-1-v1/02-architecture.md §3
/// names AllergyRecord in the vault layout but never shapes it) — this shape
/// was agreed directly with the user: mirrors FamilyHistoryEntry's fields for
/// consistency, reusing the same unverified-fact Certainty register.
class AllergyRecord {
  final AllergyRecordId id;
  final PersonId personId;
  final String substance;
  final String reaction;
  final String? severity;
  final Certainty certainty;
  final String? notes;

  const AllergyRecord({
    required this.id,
    required this.personId,
    required this.substance,
    required this.reaction,
    this.severity,
    required this.certainty,
    this.notes,
  });
}
