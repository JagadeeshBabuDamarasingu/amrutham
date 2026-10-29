import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The device DB key encrypts the local Realm cache (db/connection.dart).
/// It is independent from the export/recovery passphrase — a separate key,
/// built with the vault in M5 — and the two must never be conflated. See
/// specs/phase-1-v1/02-architecture.md §8: "Two independent keys."
///
/// Pin `flutter_secure_storage`'s version strictly (see pubspec.yaml) and run
/// a full backup-then-restore test against production-shaped data before
/// ever bumping its major version — this package has a documented history of
/// migration-triggered lockout bugs, not just steady-state ones.
abstract class DbKeyProvider {
  /// Exactly 64 bytes — Realm's `Configuration.encryptionKey` requirement.
  Future<List<int>> getOrCreateDbKey();
}

class SecureStorageDbKeyProvider implements DbKeyProvider {
  static const _storageKey = 'amrutham_device_db_key';
  static const _keyLengthBytes = 64;

  final FlutterSecureStorage _storage;

  const SecureStorageDbKeyProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<List<int>> getOrCreateDbKey() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null) return base64Decode(existing);

    final random = Random.secure();
    final bytes = List<int>.generate(
      _keyLengthBytes,
      (_) => random.nextInt(256),
    );
    await _storage.write(key: _storageKey, value: base64Encode(bytes));
    return bytes;
  }
}
