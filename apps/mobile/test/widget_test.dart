// Boot smoke test. flutter_secure_storage and path_provider both need real
// platform channels, unavailable under `flutter test` — so the database
// provider is overridden with an in-memory DB, bypassing both.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/db/database.dart';
import 'package:amrutham/main.dart';
import 'package:amrutham/providers/app_providers.dart';

void main() {
  testWidgets('app boots to an empty profile list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith(
            (ref) async => AppDatabase(NativeDatabase.memory()),
          ),
        ],
        child: const AmruthamApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Amrutham'), findsOneWidget);
    expect(find.text('No profiles yet. Add your first one.'), findsOneWidget);
  });
}
