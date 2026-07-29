import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The device DB key encrypts the local SQLite cache (db/connection.dart).
/// It is independent from the export/recovery passphrase — a separate key,
/// built with the vault in M5 — and the two must never be conflated. See
/// specs/phase-1-v1/02-architecture.md §8: "Two independent keys."
///
/// Pin `flutter_secure_storage`'s version strictly (see pubspec.yaml) and run
/// a full backup-then-restore test against production-shaped data before
/// ever bumping its major version — this package has a documented history of
/// migration-triggered lockout bugs, not just steady-state ones.
abstract class DbKeyProvider {
  Future<String> getOrCreateDbKey();
}

class SecureStorageDbKeyProvider implements DbKeyProvider {
  static const _storageKey = 'amrutham_device_db_key';
  static const _keyLengthBytes = 32;

  final FlutterSecureStorage _storage;

  const SecureStorageDbKeyProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String> getOrCreateDbKey() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(
      _keyLengthBytes,
      (_) => random.nextInt(256),
    );
    final key = base64UrlEncode(bytes);
    await _storage.write(key: _storageKey, value: key);
    return key;
  }
}
