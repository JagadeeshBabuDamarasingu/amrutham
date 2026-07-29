import 'package:drift/drift.dart';

part 'database.g.dart';

/// The DB is a rebuildable cache, not the source of truth (the plain-files
/// vault, built in M5, is). See specs/phase-1-v1/02-architecture.md §4.
@DriftDatabase(
  include: {
    'person.drift',
    'family_history.drift',
    'allergy.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
