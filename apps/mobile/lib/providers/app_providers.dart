import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:realm/realm.dart';

import '../crypto/key_manager.dart';
import '../crypto/onboarding_store.dart';
import '../db/connection.dart';
import '../model/allergy.dart';
import '../model/family_history.dart';
import '../model/ids.dart';
import '../model/measurement.dart';
import '../model/medication.dart';
import '../model/person.dart';
import '../model/schedule_phase.dart';
import '../reminder/reminder_repository.dart';
import '../repository/measurement_repository.dart';
import '../repository/medication_repository.dart';
import '../repository/profile_repository.dart';

final dbKeyProviderProvider = Provider<DbKeyProvider>((ref) {
  return const SecureStorageDbKeyProvider();
});

/// The device DB key must be resolved (async, secure-storage-backed) before
/// the database can be opened — see crypto/key_manager.dart.
final dbKeyProvider = FutureProvider<List<int>>((ref) {
  return ref.watch(dbKeyProviderProvider).getOrCreateDbKey();
});

final onboardingStoreProvider = Provider<OnboardingStore>((ref) {
  return const SecureStorageOnboardingStore();
});

final welcomeSeenProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingStoreProvider).welcomeSeen();
});

/// False until a recovery code has been saved and confirmed. New records are
/// gated on this (see ui/recovery_flow_screen.dart).
final recoverySetProvider = FutureProvider<bool>((ref) async {
  return await ref.watch(onboardingStoreProvider).readRecovery() != null;
});

final databaseProvider = FutureProvider<Realm>((ref) async {
  final dbKey = await ref.watch(dbKeyProvider.future);
  final realm = await openRealm(dbKey);
  ref.onDispose(realm.close);
  return realm;
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

final measurementRepositoryProvider = FutureProvider<MeasurementRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return MeasurementRepository(db);
});

/// Every reading for one person, newest first.
final measurementsProvider =
    StreamProvider.family<List<Measurement>, PersonId>((ref, personId) async* {
      final repository = await ref.watch(measurementRepositoryProvider.future);
      yield* repository.watchMeasurements(personId);
    });

/// Active courses only — what "N active medications" counts.
final activeCoursesProvider =
    Provider.family<AsyncValue<List<MedicationCourse>>, PersonId>((ref, id) {
      return ref
          .watch(medicationCoursesProvider(id))
          .whenData(
            (courses) =>
                courses.where((c) => c.status == CourseStatus.active).toList(),
          );
    });

/// One scheduled dose today.
class TodayDose {
  const TodayDose({
    required this.person,
    required this.medicationName,
    required this.doseAmount,
    required this.time,
  });

  final PersonProfile person;
  final String medicationName;
  final String doseAmount;
  final TimeOfDayLite time;
}

class TimeOfDayLite implements Comparable<TimeOfDayLite> {
  const TimeOfDayLite(this.hour, this.minute);
  final int hour;
  final int minute;

  @override
  int compareTo(TimeOfDayLite other) =>
      (hour * 60 + minute) - (other.hour * 60 + other.minute);

  String get label {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'am' : 'pm'}';
  }
}

/// Today's scheduled doses across the family, earliest first.
// ponytail: honours daysOfWeek and the phase's start/end but treats every
// non-PRN phase as "at its times each day"; multi-day periods (every 3 days)
// aren't modelled here. Mirror ReminderRepository's rules if that matters.
final todaysDosesProvider = FutureProvider<List<TodayDose>>((ref) async {
  final people = await ref.watch(profilesProvider.future);
  final repository = await ref.watch(medicationRepositoryProvider.future);
  final weekday = DateTime.now().weekday;
  final doses = <TodayDose>[];
  for (final person in people) {
    final courses = await ref.watch(medicationCoursesProvider(person.id).future);
    final names = {for (final c in courses) c.id: c.medicationName};
    final phases = await repository.activeNonConflictedPhasesForPerson(
      person.id,
    );
    for (final phase in phases) {
      final days = phase.daysOfWeek;
      if (days != null && days.isNotEmpty && !days.contains(weekday)) continue;
      for (final t in phase.timesOfDay) {
        final parts = t.split(':');
        doses.add(
          TodayDose(
            person: person,
            medicationName: names[phase.courseId] ?? 'Medicine',
            doseAmount: phase.doseAmount,
            time: TimeOfDayLite(int.parse(parts[0]), int.parse(parts[1])),
          ),
        );
      }
    }
  }
  doses.sort((a, b) => a.time.compareTo(b.time));
  return doses;
});

/// Whose numbers the Today tab shows; null means the first person.
final selectedPersonIdProvider = StateProvider<PersonId?>((ref) => null);
