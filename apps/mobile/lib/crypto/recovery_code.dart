import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// The user-held recovery code: 24 characters shown as six groups of four.
///
/// It is the "export/recovery passphrase" of specs/phase-1-v1/02-architecture.md
/// §8, independent of the device DB key (crypto/key_manager.dart). The code
/// itself is never stored — only a salted Argon2id verifier ([RecoveryRecord]).
class RecoveryCode {
  const RecoveryCode._(this.value);

  /// 31 characters with no 0/O/1/I/L, so a handwritten copy can't be misread.
  static const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const groupCount = 6;
  static const groupLength = 4;

  /// 24 characters, no separators.
  final String value;

  /// ~119 bits, drawn with rejection sampling so every character is equally
  /// likely (256 isn't a multiple of 31).
  factory RecoveryCode.generate({Random? random}) {
    final rng = random ?? Random.secure();
    final limit = 256 - 256 % alphabet.length;
    final chars = StringBuffer();
    while (chars.length < groupCount * groupLength) {
      final byte = rng.nextInt(256);
      if (byte < limit) chars.write(alphabet[byte % alphabet.length]);
    }
    return RecoveryCode._(chars.toString());
  }

  /// Accepts what a person types: any case, spaces or dashes between groups.
  static RecoveryCode? parse(String input) {
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    final valid =
        cleaned.length == groupCount * groupLength &&
        cleaned.split('').every(alphabet.contains);
    return valid ? RecoveryCode._(cleaned) : null;
  }

  List<String> get groups => [
    for (var i = 0; i < groupCount; i++)
      value.substring(i * groupLength, (i + 1) * groupLength),
  ];

  /// `K7QM-2WXD-...`, for display and for the shared/saved copy.
  String get formatted => groups.join('-');
}

/// What the device keeps so it can later check a typed code: a random salt and
/// a hash of the Argon2id-derived key. Neither reveals the code.
class RecoveryRecord {
  const RecoveryRecord({required this.salt, required this.verifier});

  final List<int> salt;
  final List<int> verifier;

  Map<String, String> toJson() => {
    'salt': base64Encode(salt),
    'verifier': base64Encode(verifier),
  };

  factory RecoveryRecord.fromJson(Map<String, dynamic> json) => RecoveryRecord(
    salt: base64Decode(json['salt'] as String),
    verifier: base64Decode(json['verifier'] as String),
  );

  /// Derives on a background isolate: pure-Dart Argon2id takes seconds.
  static Future<RecoveryRecord> create(RecoveryCode code, {Random? random}) {
    final rng = random ?? Random.secure();
    final salt = List<int>.generate(16, (_) => rng.nextInt(256));
    return Isolate.run(() => _derive(code.value, salt));
  }

  Future<bool> matches(RecoveryCode code) async {
    final other = await Isolate.run(() => _derive(code.value, salt));
    // Constant-time compare: cheap, and keeps this safe to reuse.
    var diff = other.verifier.length ^ verifier.length;
    for (var i = 0; i < verifier.length && i < other.verifier.length; i++) {
      diff |= other.verifier[i] ^ verifier[i];
    }
    return diff == 0;
  }
}

// ponytail: memory 19456 KiB / 2 passes are the spec's starting values; spec
// §8 says benchmark on a low-end phone before the vault export locks them in.
Future<RecoveryRecord> _derive(String code, List<int> salt) async {
  final key = await Argon2id(
    memory: 19456,
    parallelism: 1,
    iterations: 2,
    hashLength: 32,
  ).deriveKeyFromPassword(password: code, nonce: salt);
  final verifier = await Sha256().hash(await key.extractBytes());
  return RecoveryRecord(salt: salt, verifier: verifier.bytes);
}
