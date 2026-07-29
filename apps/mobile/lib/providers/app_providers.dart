import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crypto/key_manager.dart';
import '../db/connection.dart';
// See medication_repository.dart's import comment: drift's auto-named
// `Table` subclasses (not the `AS ...Row` data classes) collide with our
// domain-model classes of the same name.
import '../db/database.dart'
    hide AllergyRecord, FamilyHistoryEntry, MedicationCourse, SchedulePhase;
import '../model/allergy.dart';
import '../model/family_history.dart';
import '../model/ids.dart';
import '../model/medication.dart';
import '../model/person.dart';
import '../model/schedule_phase.dart';
import '../reminder/reminder_repository.dart';
import '../repository/medication_repository.dart';
import '../repository/profile_repository.dart';

final dbKeyProviderProvider = Provider<DbKeyProvider>((ref) {
  return const SecureStorageDbKeyProvider();
});

/// The device DB key must be resolved (async, secure-storage-backed) before
/// the database can be opened — see crypto/key_manager.dart.
final dbKeyProvider = FutureProvider<String>((ref) {
  return ref.watch(dbKeyProviderProvider).getOrCreateDbKey();
});

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final dbKey = await ref.watch(dbKeyProvider.future);
  final db = AppDatabase(openConnection(dbKey));
  ref.onDispose(db.close);
  return db;
});

final profileRepositoryProvider = FutureProvider<ProfileRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return ProfileRepository(db);
});

final profilesProvider = StreamProvider<List<PersonProfile>>((ref) async* {
  final repository = await ref.watch(profileRepositoryProvider.future);
  yield* repository.watchProfiles();
});

final familyHistoryProvider =
    StreamProvider.family<List<FamilyHistoryEntry>, PersonId>((
      ref,
      personId,
    ) async* {
      final repository = await ref.watch(profileRepositoryProvider.future);
      yield* repository.watchFamilyHistory(personId);
    });

final allergiesProvider = StreamProvider.family<List<AllergyRecord>, PersonId>(
  (ref, personId) async* {
    final repository = await ref.watch(profileRepositoryProvider.future);
    yield* repository.watchAllergies(personId);
  },
);

/// The initialized plugin instance — overridden in main() after
/// FlutterLocalNotificationsPlugin.initialize() has run, since arming a
/// reminder before that would silently fail. See main.dart.
final notificationsPluginProvider = Provider<FlutterLocalNotificationsPlugin>(
  (ref) => throw UnimplementedError(
    'notificationsPluginProvider must be overridden in main()',
  ),
);

final medicationRepositoryProvider = FutureProvider<MedicationRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return MedicationRepository(db);
});

final reminderRepositoryProvider = FutureProvider<ReminderRepository>((
  ref,
) async {
  final medicationRepository = await ref.watch(
    medicationRepositoryProvider.future,
  );
  final notifications = ref.watch(notificationsPluginProvider);
  return ReminderRepository(notifications, medicationRepository);
});

final medicationCoursesProvider =
    StreamProvider.family<List<MedicationCourse>, PersonId>((
      ref,
      personId,
    ) async* {
      final repository = await ref.watch(medicationRepositoryProvider.future);
      yield* repository.watchCoursesForPerson(personId);
    });

final schedulePhasesProvider =
    StreamProvider.family<List<SchedulePhase>, MedicationCourseId>((
      ref,
      courseId,
    ) async* {
      final repository = await ref.watch(medicationRepositoryProvider.future);
      yield* repository.watchPhasesForCourse(courseId);
    });
