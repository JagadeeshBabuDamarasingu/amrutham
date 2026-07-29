import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crypto/key_manager.dart';
import '../db/connection.dart';
import '../db/database.dart';
import '../model/allergy.dart';
import '../model/family_history.dart';
import '../model/ids.dart';
import '../model/person.dart';
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
