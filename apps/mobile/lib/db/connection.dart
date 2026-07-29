import 'dart:io';

// QueryExecutor and LazyDatabase live in drift.dart's export surface;
// package:drift/native.dart only imports it internally, it doesn't
// re-export it — both imports are needed.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Opens the encrypted local database. `dbKey` is the device DB key from
/// [DbKeyProvider] (crypto/key_manager.dart) — never the export/recovery
/// passphrase, which is a separate key used only by the vault (M5). See
/// specs/phase-1-v1/02-architecture.md §4 and §8.
QueryExecutor openConnection(String dbKey) {
  return LazyDatabase(() async {
    // App-support dir, not the user-visible documents dir: this file is an
    // internal rebuildable cache, not the vault the user owns and can see.
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'amrutham.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        // PRAGMA doesn't support bound parameters; the key never contains
        // user-typed text (see key_manager.dart) but escape defensively.
        final escaped = dbKey.replaceAll("'", "''");
        rawDb.execute("PRAGMA key = '$escaped';");
        assert(_debugHasCipher(rawDb));
      },
    );
  });
}

/// NOT `PRAGMA cipher_version` — that's SQLCipher-specific and silently
/// returns empty even when encryption IS active.
bool _debugHasCipher(Database rawDb) {
  return rawDb.select('PRAGMA cipher;').isNotEmpty;
}
