// Zero-cost ID wrappers — prevents passing e.g. an AllergyRecordId where a
// PersonId is expected, a real bug class in a schema this cross-referenced.
// See specs/phase-1-v1/02-architecture.md §3.

extension type const PersonId(String value) {}

extension type const FamilyHistoryEntryId(String value) {}

extension type const AllergyRecordId(String value) {}

extension type const MedicationCourseId(String value) {}

extension type const SchedulePhaseId(String value) {}
