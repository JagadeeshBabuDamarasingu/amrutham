import 'certainty.dart';
import 'ids.dart';

/// Unverified recorded facts, never risk-scored. Output register anywhere
/// this surfaces is strictly plain-factual ("3 first-degree relatives with
/// type-2 diabetes — worth discussing with a doctor"), never a score or a
/// red/yellow/green indicator. See specs/phase-1-v1/01-features.md F1 and
/// specs/out-of-scope.md.
class FamilyHistoryEntry {
  final FamilyHistoryEntryId id;
  final PersonId personId;
  final String relationship; // free text, not enum-locked
  final String conditionText; // free text, always present
  final String? conditionCode; // optional SNOMED code, enrichment only
  final int? onsetAgeApprox;
  final String? outcome;
  final Certainty certainty;
  final String? notes;

  const FamilyHistoryEntry({
    required this.id,
    required this.personId,
    required this.relationship,
    required this.conditionText,
    this.conditionCode,
    this.onsetAgeApprox,
    this.outcome,
    required this.certainty,
    this.notes,
  });
}
